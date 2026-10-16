package deploy

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"time"
)

type requirement struct {
	name     string
	args     []string
	minimum  string
	required bool
}

func requirements(o Options) []requirement {
	r := []requirement{{"jq", []string{"--version"}, "1.6", true}, {"go", []string{"version"}, "1.23", true}}
	if has(o.Runtimes, "bun") {
		r = append(r, requirement{"bun", []string{"--version"}, "1.4.2", true})
	}
	if has(o.Runtimes, "fnm") {
		r = append(r, requirement{"fnm", []string{"--version"}, "1.39.0", true})
	}
	if has(o.Components, "git") {
		r = append(r, requirement{"git", []string{"--version"}, "2.37", true})
		if o.LFS {
			r = append(r, requirement{"git-lfs", []string{"version"}, "3.0", true})
		}
	}
	if has(o.Components, "shell") {
		for _, s := range strings.Split(o.Shells, ",") {
			switch s {
			case "zsh":
				r = append(r, requirement{"zsh", []string{"--version"}, "5.8", true})
			case "bash":
				r = append(r, requirement{"bash", []string{"--version"}, "3.2", true})
			case "fish":
				r = append(r, requirement{"fish", []string{"--version"}, "3.6", true})
			case "powershell":
				r = append(r, requirement{"pwsh", []string{"-NoProfile", "-NonInteractive", "-Command", "$PSVersionTable.PSVersion.ToString()"}, "7.4", true})
			}
		}
		if o.Profile != "minimal" && o.Profile != "container" {
			for _, v := range []requirement{{"eza", []string{"--version"}, "0.20", false}, {"rg", []string{"--version"}, "13.0", false}, {"fd", []string{"--version"}, "8.0", false}, {"zoxide", []string{"--version"}, "0.9", false}, {"direnv", []string{"version"}, "2.32", false}, {"atuin", []string{"--version"}, "18.23.0", false}, {"starship", []string{"--version"}, "1.26.0", false}} {
				r = append(r, v)
			}
		}
	}
	return r
}

func doctor(o Options, out io.Writer) error {
	failures := 0
	fmt.Fprintf(out, "Platform: %s/%s; profile: %s\n", runtime.GOOS, runtime.GOARCH, o.Profile)
	for _, r := range requirements(o) {
		p, e := exec.LookPath(r.name)
		if r.name == "fd" && e != nil {
			p, e = exec.LookPath("fdfind")
		}
		if e != nil {
			fmt.Fprintf(out, "missing\t%s (minimum %s; required=%t)\n", r.name, r.minimum, r.required)
			if r.required {
				failures++
			}
			continue
		}
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		cmd := exec.CommandContext(ctx, p, r.args...)
		if r.name == "go" {
			cmd.Env = append(os.Environ(), "GOTOOLCHAIN=local")
		}
		b, e := cmd.CombinedOutput()
		cancel()
		// Do not echo arbitrary executable output: it can contain paths or secrets.
		v := firstVersion(string(b))
		if e != nil || !atLeast(v, r.minimum) {
			label := "optional incompatible"
			if r.required {
				label = "incompatible"
				failures++
			}
			fmt.Fprintf(out, "%s\t%s (need %s; detected %s)\n", label, r.name, r.minimum, v)
			continue
		}
		fmt.Fprintf(out, "ok\t%s %s\n", r.name, v)
	}
	if _, e := exec.LookPath("fd"); e != nil {
		if _, e = exec.LookPath("fdfind"); e == nil {
			fmt.Fprintln(out, "ok\tfdfind fallback")
		} else {
			fmt.Fprintln(out, "optional missing\tfd/fdfind")
		}
	}
	if o.Mode == "symlink" {
		fmt.Fprintln(out, "Symlink mode: repository edits immediately affect linked configurations.")
	}
	if idx, e := loadIndex(o); e != nil {
		return e
	} else {
		for p, r := range idx.Active {
			f, e := fingerprint(p)
			if e != nil {
				return e
			}
			if !same(f, r.Deployed) {
				fmt.Fprintf(out, "drift\t%s\n", p)
				failures++
			} else if r.Deployed.Kind == "symlink" && !readableManagedSource(o.Repo, r.Deployed.Target) {
				fmt.Fprintf(out, "broken source\t%s\n", p)
				failures++
			}
		}
	}
	if pending(o) != "" {
		failures++
		fmt.Fprintln(out, "Interrupted deployment: use rollback --apply.")
	}
	if failures > 0 {
		return fmt.Errorf("%d health checks failed", failures)
	}
	return nil
}

// Only inspect the recorded deployed source, never a pre-adoption link target.
func readableManagedSource(repo, path string) bool {
	if !within(repo, path) || safeParents(path) != nil {
		return false
	}
	info, err := os.Lstat(path)
	if err != nil || !info.Mode().IsRegular() {
		return false
	}
	file, err := os.Open(path)
	if err != nil {
		return false
	}
	return file.Close() == nil
}

var versionPattern = regexp.MustCompile(`[0-9]+(?:\.[0-9]+)+`)

func firstVersion(s string) string {
	if v := versionPattern.FindString(s); v != "" {
		return v
	}
	return "unknown"
}
func atLeast(v, min string) bool {
	a, b := strings.Split(v, "."), strings.Split(min, ".")
	for n := 0; n < len(b); n++ {
		x := 0
		if n < len(a) {
			var e error
			x, e = strconv.Atoi(a[n])
			if e != nil {
				return false
			}
		}
		y, _ := strconv.Atoi(b[n])
		if x != y {
			return x > y
		}
	}
	return v != "unknown"
}

// Package operations use the native manager, never a parsed custom manifest.
// Commands only install missing tools; managers can still resolve dependencies.
func packages(o Options, out io.Writer) error {
	manager := os.Getenv("DOTFILES_PACKAGE_MANAGER")
	if manager == "" {
		candidates := []string{"apt-get", "dnf", "pacman", "zypper", "apk", "pkg", "pkg_add", "brew", "winget", "scoop", "choco", "nix"}
		if runtime.GOOS == "darwin" {
			candidates = []string{"brew"}
		}
		if runtime.GOOS == "windows" {
			candidates = []string{"winget", "scoop", "choco", "nix"}
		}
		if os.Getenv("TERMUX_VERSION") != "" {
			candidates = []string{"pkg"}
		}
		for _, v := range candidates {
			if _, e := exec.LookPath(v); e == nil {
				manager = v
				break
			}
		}
	}
	mappings := map[string]map[string]string{
		"apt-get": {"go": "golang-go", "fd": "fd-find", "rg": "ripgrep", "pwsh": "", "bun": "", "fnm": "", "atuin": "", "starship": ""},
		"dnf":     {"go": "golang", "rg": "ripgrep", "fd": "fd-find", "pwsh": "powershell", "bun": "", "fnm": ""},
		"pacman":  {"go": "go", "rg": "ripgrep", "fd": "fd", "pwsh": "", "bun": "", "fnm": ""},
		"zypper":  {"go": "go", "rg": "ripgrep", "fd": "fd", "pwsh": "", "bun": "", "fnm": ""},
		"apk":     {"go": "go", "rg": "ripgrep", "fd": "fd", "pwsh": "", "bun": "", "fnm": ""},
		"brew":    {"go": "go", "rg": "ripgrep", "fd": "fd", "pwsh": "", "bun": "oven-sh/bun/bun"},
		"pkg":     {"go": "go", "rg": "ripgrep", "fd": "fd", "pwsh": "", "bun": "", "fnm": "", "atuin": ""},
		"pkg_add": {"go": "go", "rg": "ripgrep", "fd": "fd", "fish": "fish%main", "pwsh": "", "bun": "", "fnm": "", "atuin": "", "zoxide": "", "starship": "", "eza": ""},
		"winget":  {"git": "Git.Git", "git-lfs": "GitHub.GitLFS", "go": "GoLang.Go", "jq": "jqlang.jq", "bun": "Oven-sh.Bun", "pwsh": "Microsoft.PowerShell", "eza": "eza-community.eza", "rg": "BurntSushi.ripgrep.MSVC", "fd": "sharkdp.fd", "zoxide": "ajeetdsouza.zoxide", "fnm": "Schniz.fnm", "starship": "Starship.Starship", "atuin": "", "direnv": "", "zsh": "", "bash": "", "fish": ""},
		"scoop":   {"go": "go", "rg": "ripgrep", "pwsh": "pwsh", "atuin": "", "direnv": "", "zsh": "", "fish": ""},
		"choco":   {"go": "golang", "rg": "ripgrep", "pwsh": "powershell-core", "atuin": "", "direnv": "", "zsh": "", "fish": "", "eza": "", "fnm": "", "bun": ""},
		"nix":     {"go": "go", "rg": "ripgrep", "pwsh": "powershell"},
	}
	base := map[string][]string{
		"apt-get": {"apt-get", "install", "--no-upgrade", "--no-install-recommends", "-y"},
		"dnf":     {"dnf", "install", "--setopt=install_weak_deps=False", "-y"},
		"pacman":  {"pacman", "-S", "--needed"}, "zypper": {"zypper", "--non-interactive", "install", "--no-recommends"},
		"apk": {"apk", "add"}, "brew": {"brew", "install"}, "pkg": {"pkg", "install"}, "pkg_add": {"pkg_add"},
		"winget": {"winget", "install", "--exact", "--id"}, "scoop": {"scoop", "install"}, "choco": {"choco", "install", "-y"},
		"nix": {"nix", "profile", "install"},
	}
	if _, ok := mappings[manager]; !ok {
		return errors.New("no supported package manager; see docs/PACKAGES.md")
	}
	if o.Apply && o.Home != "" {
		h, _ := os.UserHomeDir()
		if o.Home != h {
			return errors.New("package installation affects the invoking machine; --home cannot target another user's packages")
		}
	}
	var missing []string
	for _, r := range requirements(o) {
		if _, e := exec.LookPath(r.name); e == nil {
			continue
		}
		if r.name == "fd" {
			if _, e := exec.LookPath("fdfind"); e == nil {
				continue
			}
		}
		name, ok := mappings[manager][r.name]
		if !ok {
			name = r.name
		}
		if manager == "pkg" && os.Getenv("TERMUX_VERSION") != "" && r.name == "go" {
			name = "golang"
		}
		if name == "" {
			fmt.Fprintf(out, "manual/pinned tool setup required: %s\n", r.name)
			missing = append(missing, r.name)
			continue
		}
		args := append(append([]string{}, base[manager]...), name)
		if manager == "nix" {
			args[len(args)-1] = "nixpkgs#" + name
		}
		fmt.Fprintln(out, strings.Join(args, " "))
		if o.Apply {
			cmd := exec.Command(args[0], args[1:]...)
			cmd.Stdin = os.Stdin
			cmd.Stdout = out
			cmd.Stderr = out
			if manager == "brew" {
				cmd.Env = append(os.Environ(), "HOMEBREW_NO_AUTO_UPDATE=1", "HOMEBREW_NO_INSTALL_UPGRADE=1")
			}
			if e := cmd.Run(); e != nil {
				return e
			}
		}
	}
	if o.Apply && len(missing) > 0 {
		return fmt.Errorf("native setup incomplete; install remaining tools explicitly: %s", strings.Join(missing, ", "))
	}
	return nil
}
