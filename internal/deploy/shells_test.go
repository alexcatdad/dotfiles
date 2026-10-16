package deploy

import (
	"bytes"
	"context"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"
)

func TestNativeShellStartup(t *testing.T) {
	shells := []string{"zsh", "bash", "fish", "powershell", "posix"}
	if runtime.GOOS == "darwin" {
		shells = append(shells, "bash-system")
	}
	for _, shell := range shells {
		t.Run(shell, func(t *testing.T) {
			if runtime.GOOS == "windows" && shell != "powershell" {
				t.Skip("Unix shells are tested natively and under WSL, not through MSYS path translation")
			}
			command := map[string]string{"zsh": "zsh", "bash": "bash", "fish": "fish", "powershell": "pwsh", "posix": "sh"}[shell]
			if shell == "bash-system" {
				shell, command = "bash", "/bin/bash"
			}
			executable, e := exec.LookPath(command)
			if e != nil {
				if has(os.Getenv("DOTFILES_REQUIRED_SHELLS"), shell) {
					t.Fatalf("required shell missing: %s", shell)
				}
				t.Skip("native shell unavailable")
			}
			o := fixture(t)
			o.Repo, _ = filepath.Abs(filepath.Join("..", ".."))
			o.Repo, _ = filepath.EvalSymlinks(o.Repo)
			o.Home = filepath.Join(filepath.Dir(o.Home), "home 'quoted 日本")
			os.Mkdir(o.Home, 0700)
			for _, path := range []string{filepath.Join(o.Home, ".local", "bin"), filepath.Join(o.Home, "bin")} {
				if e = os.MkdirAll(path, 0700); e != nil {
					t.Fatal(e)
				}
			}
			o.Config = filepath.Join(o.Home, "custom config 'quote")
			o.Data = filepath.Join(o.Home, "custom data")
			o.Cache = filepath.Join(o.Home, "custom cache")
			o.State = filepath.Join(o.Home, "state")
			// Zsh 5.9 corrupts funcstack when its automatically loaded startup
			// filename contains these multibyte characters. Keep ZDOTDIR ASCII;
			// HOME and the explicitly sourced configuration still exercise Unicode.
			o.ZshDir = filepath.Join(filepath.Dir(o.Home), "zsh configuration")
			o.PowerShellProfile = filepath.Join(o.Config, "powershell", "profile.ps1")
			o.Shells = shell
			o.Components = "shell,git,prompt,history,search"
			o.Apply = true
			if e = o.normalize(); e != nil {
				t.Fatal(e)
			}
			if e = prepareState(o); e != nil {
				t.Fatal(e)
			}
			idx, _ := loadIndex(o)
			if e = install(o, idx, io.Discard); e != nil {
				t.Fatal(e)
			}
			// vt100 keeps interactive hooks enabled without Bash 3.2's
			// meta-mode transport escapes when stdin/stderr are pipes.
			env := []string{"HOME=" + o.Home, "USERPROFILE=" + o.Home, "USER=fixture", "PATH=" + fixtureShellPath(t, o), "INPUTRC=" + filepath.Join(o.Home, ".inputrc"), "TERM=vt100", "LANG=C.UTF-8", "XDG_CONFIG_HOME=" + o.Config, "XDG_DATA_HOME=" + o.Data, "XDG_STATE_HOME=" + filepath.Join(o.Home, "state-home"), "XDG_CACHE_HOME=" + o.Cache, "NO_COLOR=1", "GOTOOLCHAIN=local"}
			for _, name := range []string{"SystemRoot", "WINDIR", "COMSPEC", "PATHEXT", "TEMP", "TMP"} {
				if v := os.Getenv(name); v != "" {
					env = append(env, name+"="+v)
				}
			}
			var modes [][]string
			switch shell {
			case "zsh":
				for _, mode := range []string{"-c", "-lc", "-ic", "-lic"} {
					modes = append(modes, []string{"-d", mode, "print -r -- READY"})
				}
				env = append(env, "ZDOTDIR="+o.ZshDir)
			case "bash":
				for _, mode := range []string{"-c", "-lc", "-ic", "-lic"} {
					modes = append(modes, []string{"--noprofile", "--norc", mode, ". \"$HOME/.bash_profile\"; . \"$HOME/.bashrc\"; printf 'READY\\n'"})
				}
			case "fish":
				probe := "source " + quoteSH(filepath.Join(o.Config, "fish", "conf.d", "dotfiles.fish")) + "; if test (contains -i -- \"$HOME/.local/bin\" $PATH) -ge (contains -i -- \"$HOME/bin\" $PATH); echo 'incorrect PATH precedence' >&2; exit 1; end; echo READY"
				modes = [][]string{{"--no-config", "-c", probe}, {"--no-config", "-ic", probe}}
			case "powershell":
				probe := "Set-Variable HOME -Value " + quotePS(o.Home) + " -Force; . " + quotePS(o.PowerShellProfile) + "; $paths = $env:PATH -split [IO.Path]::PathSeparator; if ([Array]::IndexOf($paths, (Join-Path $HOME '.local/bin')) -ge [Array]::IndexOf($paths, (Join-Path $HOME 'bin'))) { throw 'incorrect PATH precedence' }; Write-Output READY"
				modes = [][]string{{"-NoProfile", "-NonInteractive", "-Command", probe}}
			case "posix":
				modes = [][]string{{"-c", ". \"$HOME/.profile\"; printf 'READY\\n'"}}
			}
			for _, args := range modes {
				// Measure native process startup separately. Cold PowerShell JIT
				// on Windows runners is not configuration startup overhead.
				baseline := time.Duration(0)
				if shell == "powershell" {
					bare := exec.Command(executable, "-NoProfile", "-NonInteractive", "-Command", "exit 0")
					bare.Env = env
					bare.Dir = o.Home
					tick := time.Now()
					if e = bare.Run(); e != nil {
						t.Fatal(e)
					}
					baseline = time.Since(tick)
				}
				start := time.Now()
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()
				cmd := fixtureShellCommand(ctx, shell, executable, args...)
				cmd.Env = env
				cmd.Dir = o.Home
				var stderr bytes.Buffer
				cmd.Stderr = &stderr
				b, e := cmd.Output()
				if e != nil {
					t.Fatalf("%v: %v\n%s", args, e, stderr.String())
				}
				if fixtureShellText(cmd, b) != "READY" {
					t.Fatalf("noisy startup: %q", b)
				}
				for _, line := range strings.Split(stderr.String(), "\n") {
					if line == "" || shell == "bash" && (strings.Contains(line, "cannot set terminal process group") || strings.Contains(line, "no job control in this shell") || strings.Contains(line, "initialize_job_control: no job control in background: Bad file descriptor")) {
						continue
					}
					t.Errorf("startup stderr: %s", line)
				}
				if time.Since(start)-baseline > 5*time.Second {
					t.Error("configuration startup overhead exceeded 5-second regression ceiling")
				}
			}
		})
	}
}

// FreeBSD Bash can stop on job-control signals when launched interactively
// without a controlling terminal. Its base-system script tool supplies a real
// PTY while preserving argv; ordinary non-interactive probes stay pipe-based.
func fixtureShellCommand(ctx context.Context, shell, executable string, args ...string) *exec.Cmd {
	interactive := false
	for _, arg := range args {
		if arg == "--interactive" || strings.HasPrefix(arg, "-") && !strings.HasPrefix(arg, "--") && strings.Contains(arg, "i") {
			interactive = true
		}
	}
	var cmd *exec.Cmd
	if runtime.GOOS == "freebsd" && shell == "bash" && interactive {
		cmd = exec.CommandContext(ctx, "script", append([]string{"-q", "/dev/null", executable}, args...)...)
	} else {
		cmd = exec.CommandContext(ctx, executable, args...)
	}
	cmd.WaitDelay = 2 * time.Second
	return cmd
}

func fixtureShellText(cmd *exec.Cmd, output []byte) string {
	text := string(output)
	if runtime.GOOS == "freebsd" && filepath.Base(cmd.Path) == "script" {
		// script sends EOF to its PTY when our input pipe closes. FreeBSD's
		// terminal driver echoes it as ^D followed by two backspaces before
		// the child runs. Remove only that transport prefix, retaining all
		// shell output so unexpected startup messages still fail the probe.
		text = strings.TrimPrefix(text, "^D\b\b")
	}
	return strings.TrimSpace(text)
}

// Startup deliberately discovers native package directories. Shadow optional
// host tools in the highest-priority user-local directory so startup probes
// cannot execute real integrations. Tests replace individual stubs as needed.
func fixtureShellPath(t *testing.T, o Options) string {
	t.Helper()
	bin := filepath.Join(o.Home, ".local", "bin")
	if err := os.MkdirAll(bin, 0700); err != nil {
		t.Fatal(err)
	}
	// Do not inherit system Readline preferences in pipe-based startup probes.
	if err := os.WriteFile(filepath.Join(o.Home, ".inputrc"), []byte("# Isolated test Readline configuration.\n"), 0600); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"eza", "rg", "fd", "fdfind", "fnm", "zoxide", "direnv", "atuin", "starship"} {
		body := "#!/bin/sh\nexit 1\n"
		if runtime.GOOS == "windows" {
			name += ".cmd"
			body = "@exit /b 1\r\n"
		}
		if err := os.WriteFile(filepath.Join(bin, name), []byte(body), 0755); err != nil {
			t.Fatal(err)
		}
	}
	if runtime.GOOS == "windows" {
		return strings.Join([]string{filepath.Join(os.Getenv("SystemRoot"), "System32"), os.Getenv("SystemRoot")}, string(os.PathListSeparator))
	}
	return "/usr/bin:/bin"
}

func TestZshUsesSelectedDataDirectoryForPnpm(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("native Unix shell")
	}
	executable, err := exec.LookPath("zsh")
	if err != nil {
		t.Skip("native Zsh unavailable")
	}
	o := fixture(t)
	o.Repo, _ = filepath.Abs(filepath.Join("..", ".."))
	o.Repo, _ = filepath.EvalSymlinks(o.Repo)
	o.Components, o.Shells = "shell", "zsh"
	o.Data = filepath.Join(o.Home, "selected data")
	if err = os.MkdirAll(filepath.Join(o.Data, "pnpm"), 0700); err != nil {
		t.Fatal(err)
	}
	o.ZshDir = filepath.Join(filepath.Dir(o.Home), "ascii-zdotdir")
	if err = prepareState(o); err != nil {
		t.Fatal(err)
	}
	idx, _ := loadIndex(o)
	if err = install(o, idx, io.Discard); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, executable, "-d", "-c", `(( ${path[(Ie)$DOTFILES_DATA_HOME/pnpm]} )) || exit 1; print -r -- READY`)
	cmd.Env = []string{"HOME=" + o.Home, "ZDOTDIR=" + o.ZshDir, "PATH=" + fixtureShellPath(t, o), "XDG_DATA_HOME=" + filepath.Join(o.Home, "other data")}
	cmd.Dir = o.Home
	if b, err := cmd.CombinedOutput(); err != nil || strings.TrimSpace(string(b)) != "READY" {
		t.Fatalf("selected pnpm data directory missing: %v %s", err, b)
	}
}

func TestFishAbbreviationRespectsTerminalControls(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("native Unix shell")
	}
	executable, err := exec.LookPath("fish")
	if err != nil {
		if has(os.Getenv("DOTFILES_REQUIRED_SHELLS"), "fish") {
			t.Fatal("required Fish unavailable")
		}
		t.Skip("native Fish unavailable")
	}
	for _, control := range []string{"DOTFILES_ICONS=0", "NO_COLOR=1", "TERM=dumb", "TERM=xterm-256color"} {
		t.Run(control, func(t *testing.T) {
			o := fixture(t)
			source, _ := filepath.Abs(filepath.Join("..", "..", "home", ".config", "fish", "conf.d", "dotfiles.fish"))
			path := fixtureShellPath(t, o)
			if err := os.WriteFile(filepath.Join(o.Home, ".local", "bin", "eza"), []byte("#!/bin/sh\nprintf '%s\\n' \"$@\"\n"), 0755); err != nil {
				t.Fatal(err)
			}
			// Execute Fish's actual abbreviation expansion and observe the
			// arguments received by a synthetic eza, rather than matching source.
			probe := "source " + quoteSH(source) + "; set -l expansion (abbr --show dfll | string replace -r '^.* -- dfll ' ''); eval (string unescape -- $expansion)"
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			cmd := exec.CommandContext(ctx, executable, "--no-config", "-ic", probe)
			cmd.Env = []string{"HOME=" + o.Home, "PATH=" + path, "DOTFILES_PROFILE=minimal", control}
			cmd.Dir = o.Home
			var stderr bytes.Buffer
			cmd.Stderr = &stderr
			b, err := cmd.Output()
			if err != nil {
				t.Fatalf("Fish abbreviation: %v %s", err, stderr.String())
			}
			want := "--icons=never"
			if control == "TERM=xterm-256color" {
				want = "--icons"
			}
			if !strings.Contains("\n"+string(b), "\n"+want+"\n") || want == "--icons=never" && strings.Contains("\n"+string(b), "\n--icons\n") {
				t.Fatalf("%s: eza arguments %q", control, b)
			}
		})
	}
}

func TestNativeLanguageToolPaths(t *testing.T) {
	for _, shell := range []string{"fish", "powershell"} {
		t.Run(shell, func(t *testing.T) {
			if runtime.GOOS == "windows" && shell != "powershell" {
				t.Skip("Unix shells are tested natively, not through MSYS path translation")
			}
			command := "fish"
			if shell == "powershell" {
				command = "pwsh"
			}
			executable, err := exec.LookPath(command)
			if err != nil {
				if has(os.Getenv("DOTFILES_REQUIRED_SHELLS"), shell) {
					t.Fatal(err)
				}
				t.Skip("native shell unavailable")
			}
			for _, scenario := range []string{"defaults", "gobin", "gopath"} {
				t.Run(scenario, func(t *testing.T) {
					o := fixture(t)
					pnpm, cargo, gobin := filepath.Join(o.Data, "pnpm"), filepath.Join(o.Home, ".cargo", "bin"), filepath.Join(o.Home, "go", "bin")
					env := []string{"HOME=" + o.Home, "USERPROFILE=" + o.Home, "PATH=" + fixtureShellPath(t, o), "DOTFILES_DATA_HOME=" + o.Data, "DOTFILES_CONFIG_HOME=" + o.Config}
					if scenario != "defaults" {
						pnpm, cargo = filepath.Join(o.Home, "custom pnpm"), filepath.Join(o.Home, "custom cargo", "bin")
						env = append(env, "PNPM_HOME="+pnpm, "CARGO_HOME="+filepath.Dir(cargo))
						if scenario == "gobin" {
							gobin = filepath.Join(o.Home, "custom go bin")
							env = append(env, "GOBIN="+gobin, "GOPATH="+filepath.Join(o.Home, "unused go"))
						} else {
							gobin = filepath.Join(o.Home, "custom go", "bin")
							env = append(env, "GOPATH="+filepath.Dir(gobin))
						}
					}
					for _, p := range []string{pnpm, cargo, gobin} {
						if err := os.MkdirAll(p, 0700); err != nil {
							t.Fatal(err)
						}
					}
					source, _ := filepath.Abs(filepath.Join("..", "..", "home", ".config", "fish", "conf.d", "dotfiles.fish"))
					probe := "source " + quoteSH(source) + "; for p in " + quoteSH(pnpm) + " " + quoteSH(cargo) + " " + quoteSH(gobin) + "; contains -- $p $PATH; or exit 1; end; echo READY"
					args := []string{"--no-config", "-c", probe}
					if shell == "powershell" {
						source, _ = filepath.Abs(filepath.Join("..", "..", "home", ".config", "powershell", "profile.ps1"))
						probe = "Set-Variable HOME -Value " + quotePS(o.Home) + " -Force; . " + quotePS(source) + "; $paths = $env:PATH -split [IO.Path]::PathSeparator; foreach ($p in @(" + quotePS(pnpm) + ", " + quotePS(cargo) + ", " + quotePS(gobin) + ")) { if ($paths -notcontains $p) { throw 'missing language-tool path' } }; Write-Output READY"
						args = []string{"-NoProfile", "-NonInteractive", "-Command", probe}
					}
					for _, name := range []string{"SystemRoot", "WINDIR", "COMSPEC", "PATHEXT", "TEMP", "TMP"} {
						if v := os.Getenv(name); v != "" {
							env = append(env, name+"="+v)
						}
					}
					ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
					defer cancel()
					cmd := exec.CommandContext(ctx, executable, args...)
					cmd.Env, cmd.Dir = env, o.Home
					if b, err := cmd.CombinedOutput(); err != nil || strings.TrimSpace(string(b)) != "READY" {
						t.Fatalf("language-tool paths: %v %s", err, b)
					}
				})
			}
		})
	}
}

func TestPowerShellPromptConfigSelection(t *testing.T) {
	executable, err := exec.LookPath("pwsh")
	if err != nil {
		if has(os.Getenv("DOTFILES_REQUIRED_SHELLS"), "powershell") {
			t.Fatal(err)
		}
		t.Skip("native PowerShell unavailable")
	}
	for _, scenario := range []string{"missing", "present", "override"} {
		t.Run(scenario, func(t *testing.T) {
			o := fixture(t)
			env := []string{"HOME=" + o.Home, "USERPROFILE=" + o.Home, "PATH=" + fixtureShellPath(t, o), "DOTFILES_CONFIG_HOME=" + o.Config}
			want := ""
			if scenario != "missing" {
				if err := os.MkdirAll(o.Config, 0700); err != nil {
					t.Fatal(err)
				}
				want = filepath.Join(o.Config, "starship.toml")
				if err := os.WriteFile(want, []byte("add_newline = false\n"), 0600); err != nil {
					t.Fatal(err)
				}
			}
			if scenario == "override" {
				want = filepath.Join(o.Home, "chosen prompt.toml")
				env = append(env, "STARSHIP_CONFIG="+want)
			}
			for _, name := range []string{"SystemRoot", "WINDIR", "COMSPEC", "PATHEXT", "TEMP", "TMP"} {
				if v := os.Getenv(name); v != "" {
					env = append(env, name+"="+v)
				}
			}
			source, _ := filepath.Abs(filepath.Join("..", "..", "home", ".config", "powershell", "profile.ps1"))
			probe := "Set-Variable HOME -Value " + quotePS(o.Home) + " -Force; . " + quotePS(source) + "; if ([string]$env:STARSHIP_CONFIG -ne " + quotePS(want) + ") { throw 'unexpected Starship override' }; Write-Output READY"
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			cmd := exec.CommandContext(ctx, executable, "-NoProfile", "-NonInteractive", "-Command", probe)
			cmd.Env, cmd.Dir = env, o.Home
			if b, err := cmd.CombinedOutput(); err != nil || strings.TrimSpace(string(b)) != "READY" {
				t.Fatalf("prompt config selection: %v %s", err, b)
			}
		})
	}
}
