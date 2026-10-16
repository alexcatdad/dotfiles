package deploy

import (
	"bytes"
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
	for _, shell := range []string{"zsh", "bash", "fish", "powershell", "posix"} {
		t.Run(shell, func(t *testing.T) {
			if runtime.GOOS == "windows" && shell != "powershell" {
				t.Skip("Unix shells are tested natively and under WSL, not through MSYS path translation")
			}
			command := map[string]string{"zsh": "zsh", "bash": "bash", "fish": "fish", "powershell": "pwsh", "posix": "sh"}[shell]
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
			env := []string{"HOME=" + o.Home, "USERPROFILE=" + o.Home, "USER=fixture", "PATH=" + os.Getenv("PATH"), "TERM=xterm-256color", "LANG=C.UTF-8", "XDG_CONFIG_HOME=" + o.Config, "XDG_DATA_HOME=" + o.Data, "XDG_STATE_HOME=" + filepath.Join(o.Home, "state-home"), "XDG_CACHE_HOME=" + o.Cache, "NO_COLOR=1", "GOTOOLCHAIN=local"}
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
				modes = [][]string{{"--no-config", "-c", "source " + quoteSH(filepath.Join(o.Config, "fish", "conf.d", "dotfiles.fish")) + "; echo READY"}, {"--no-config", "-ic", "source " + quoteSH(filepath.Join(o.Config, "fish", "conf.d", "dotfiles.fish")) + "; echo READY"}}
			case "powershell":
				modes = [][]string{{"-NoProfile", "-NonInteractive", "-Command", ". " + quotePS(o.PowerShellProfile) + "; Write-Output READY"}}
			case "posix":
				modes = [][]string{{"-c", ". \"$HOME/.profile\"; printf 'READY\\n'"}}
			}
			for _, args := range modes {
				start := time.Now()
				cmd := exec.Command(executable, args...)
				cmd.Env = env
				cmd.Dir = o.Home
				var stderr bytes.Buffer
				cmd.Stderr = &stderr
				b, e := cmd.Output()
				if e != nil {
					t.Fatalf("%v: %v\n%s", args, e, stderr.String())
				}
				if strings.TrimSpace(string(b)) != "READY" {
					t.Fatalf("noisy startup: %q", b)
				}
				for _, line := range strings.Split(stderr.String(), "\n") {
					if line == "" || shell == "bash" && (strings.Contains(line, "cannot set terminal process group") || strings.Contains(line, "no job control in this shell")) {
						continue
					}
					t.Errorf("startup stderr: %s", line)
				}
				if time.Since(start) > 5*time.Second {
					t.Error("minimal startup exceeded 5-second regression ceiling")
				}
			}
		})
	}
}
