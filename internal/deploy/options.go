package deploy

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

type Options struct {
	Repo, Home, Config, Data, State, Cache, ZshDir, PowerShellProfile string
	Components, Shells, Profile, Mode, Prompt, Terminal, Machine      string
	Replace, Apply, LFS                                               bool
	Toolset, Prefix, TargetOS, TargetArch, Libc                       string
	PluginDir                                                         string
	Runtimes                                                          string
	Offline, DownloadOnly, Upgrade                                    bool
}

func defaults() Options {
	h, _ := os.UserHomeDir()
	return Options{Repo: ".", Home: h, Components: "shell,git,prompt,history,search", Shells: "zsh", Profile: "server", Mode: "copy", Prompt: "auto", Runtimes: "none"}
}

func parse(args []string, out io.Writer) (Options, error) {
	o := defaults()
	f := flag.NewFlagSet("dotfiles", flag.ContinueOnError)
	f.SetOutput(out)
	f.StringVar(&o.Repo, "repo", o.Repo, "reviewed repository directory")
	f.StringVar(&o.Home, "home", o.Home, "confirmed target home")
	f.StringVar(&o.Config, "config-dir", "", "target XDG config directory")
	f.StringVar(&o.Data, "data-dir", "", "target XDG data directory")
	f.StringVar(&o.State, "state-dir", "", "private deployment state (outside repository)")
	f.StringVar(&o.Cache, "cache-dir", "", "target XDG cache directory")
	f.StringVar(&o.ZshDir, "zsh-dir", "", "ZDOTDIR; home receives a bootstrap when different")
	f.StringVar(&o.PowerShellProfile, "powershell-profile", "", "exact CurrentUserAllHosts profile path")
	f.StringVar(&o.Components, "components", o.Components, "shell,git,prompt,history,search,terminal,agents,skills,machine")
	f.StringVar(&o.Shells, "shells", o.Shells, "comma-separated zsh,bash,fish,powershell,posix")
	f.StringVar(&o.Profile, "profile", o.Profile, "minimal,server,desktop,container")
	f.StringVar(&o.Mode, "mode", o.Mode, "copy or symlink (rendered entrypoints always use copies)")
	f.StringVar(&o.Prompt, "prompt", o.Prompt, "auto,full,minimal,ascii; auto follows profile")
	f.StringVar(&o.Terminal, "terminal", "", "ghostty,kitty,alacritty,wezterm,windows-terminal")
	f.StringVar(&o.Machine, "machine", "", "explicit reviewed source inside machines/")
	f.BoolVar(&o.Replace, "replace", false, "back up and replace reviewed conflicting files on first adoption")
	f.BoolVar(&o.Apply, "apply", false, "perform the previewed operation")
	f.BoolVar(&o.LFS, "git-lfs", false, "include optional Git LFS filters")
	f.StringVar(&o.Toolset, "tools", "starship,atuin", "pinned tools to prepare")
	f.StringVar(&o.Runtimes, "runtimes", o.Runtimes, "none, bun, fnm, or bun,fnm; explicit opt-in only")
	f.StringVar(&o.PluginDir, "plugin-dir", "", "Zsh plugin directory; default XDG data/zsh/plugins")
	f.StringVar(&o.Prefix, "prefix", "", "binary directory; default target ~/.local/bin")
	f.StringVar(&o.TargetOS, "target-os", runtime.GOOS, "tool asset OS; foreign targets require --download-only")
	f.StringVar(&o.TargetArch, "target-arch", runtime.GOARCH, "tool asset Go architecture")
	f.StringVar(&o.Libc, "libc", "", "gnu or musl; Linux detected from loader")
	f.BoolVar(&o.Offline, "offline", false, "use verified cached tool archives only")
	f.BoolVar(&o.DownloadOnly, "download-only", false, "cache pinned archives without installing binaries")
	f.BoolVar(&o.Upgrade, "upgrade", false, "explicitly replace existing binaries in --prefix")
	if err := f.Parse(args); err != nil {
		return o, err
	}
	if f.NArg() != 0 {
		return o, errors.New("unexpected positional arguments")
	}
	return o, o.normalize()
}

func (o *Options) normalize() error {
	var err error
	for _, p := range []*string{&o.Repo, &o.Home} {
		*p, err = filepath.Abs(*p)
		if err != nil {
			return err
		}
	}
	// Explicit --home never inherits the controlling user's XDG directories.
	nativeHome, _ := os.UserHomeDir()
	for _, v := range []struct {
		p             *string
		env, fallback string
	}{
		{&o.Config, "XDG_CONFIG_HOME", filepath.Join(o.Home, ".config")},
		{&o.Data, "XDG_DATA_HOME", filepath.Join(o.Home, ".local", "share")},
		{&o.State, "XDG_STATE_HOME", filepath.Join(o.Home, ".local", "state")},
		{&o.Cache, "XDG_CACHE_HOME", filepath.Join(o.Home, ".cache")},
	} {
		if *v.p == "" {
			*v.p = v.fallback
			if o.Home == nativeHome && filepath.IsAbs(os.Getenv(v.env)) {
				*v.p = os.Getenv(v.env)
			}
			if v.env == "XDG_STATE_HOME" {
				*v.p = filepath.Join(*v.p, "dotfiles")
			}
		}
		if !filepath.IsAbs(*v.p) {
			return fmt.Errorf("%s must be absolute", v.env)
		}
		*v.p = filepath.Clean(*v.p)
	}
	if o.ZshDir == "" {
		o.ZshDir = o.Home
	}
	if o.Prefix == "" {
		o.Prefix = filepath.Join(o.Home, ".local", "bin")
	}
	if o.PluginDir == "" {
		o.PluginDir = filepath.Join(o.Data, "zsh", "plugins")
	}
	if !filepath.IsAbs(o.PluginDir) {
		return errors.New("--plugin-dir must be absolute")
	}
	if !filepath.IsAbs(o.Prefix) {
		return errors.New("--prefix must be absolute")
	}
	if !filepath.IsAbs(o.ZshDir) {
		return errors.New("--zsh-dir must be absolute")
	}
	if o.PowerShellProfile == "" {
		o.PowerShellProfile = filepath.Join(o.Config, "powershell", "profile.ps1")
		if runtime.GOOS == "windows" {
			o.PowerShellProfile = filepath.Join(o.Home, "Documents", "PowerShell", "profile.ps1")
		}
	}
	if !filepath.IsAbs(o.PowerShellProfile) {
		return errors.New("--powershell-profile must be absolute")
	}
	if !member(o.Mode, "copy", "symlink") {
		return errors.New("mode must be copy or symlink")
	}
	if !member(o.Profile, "minimal", "server", "desktop", "container") {
		return errors.New("unknown profile")
	}
	if o.Prompt == "auto" {
		o.Prompt = "full"
		if member(o.Profile, "minimal", "container") {
			o.Prompt = "minimal"
		}
	}
	if !member(o.Prompt, "full", "minimal", "ascii") {
		return errors.New("unknown prompt")
	}
	if o.Runtimes != "none" {
		if err = selection(o.Runtimes, "bun", "fnm"); err != nil {
			return err
		}
	}
	if err = selection(o.Components, "shell", "git", "prompt", "history", "search", "terminal", "agents", "skills", "machine"); err != nil {
		return err
	}
	if err = selection(o.Shells, "zsh", "bash", "fish", "powershell", "posix"); err != nil {
		return err
	}
	if has(o.Components, "terminal") && !member(o.Terminal, "ghostty", "kitty", "alacritty", "wezterm", "windows-terminal") {
		return errors.New("terminal component requires --terminal")
	}
	if has(o.Components, "machine") && o.Machine == "" {
		return errors.New("machine component requires --machine")
	}
	if within(o.Repo, o.State) {
		return errors.New("deployment state must be outside the repository")
	}
	archives := filepath.Join(o.Cache, "dotfiles", "archives")
	if within(o.Repo, o.Cache) || within(o.Repo, archives) || within(archives, o.Repo) {
		return errors.New("download caches must be outside the repository")
	}
	return nil
}

func member(s string, choices ...string) bool {
	for _, c := range choices {
		if s == c {
			return true
		}
	}
	return false
}
func has(s, key string) bool { return member(key, strings.Split(s, ",")...) }
func selection(s string, choices ...string) error {
	seen := map[string]bool{}
	for _, v := range strings.Split(s, ",") {
		if !member(v, choices...) || seen[v] {
			return fmt.Errorf("invalid or repeated selection %q", v)
		}
		seen[v] = true
	}
	return nil
}
func within(root, path string) bool {
	rel, err := filepath.Rel(root, path)
	return err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator))
}
