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
)

func TestRuntimesAreOptInAndFailedInitializersAreNotEvaluated(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("native Unix fixture executable; PowerShell uses the same success-only initialization contract")
	}
	for _, shell := range []string{"zsh", "bash"} {
		for _, scenario := range []string{"baseline", "opt-in", "failed-init"} {
			t.Run(shell+"/"+scenario, func(t *testing.T) {
				executable, e := exec.LookPath(shell)
				if e != nil {
					t.Skip("native shell unavailable")
				}
				o := fixture(t)
				o.Repo, _ = filepath.Abs(filepath.Join("..", ".."))
				o.Repo, _ = filepath.EvalSymlinks(o.Repo)
				o.ZshDir = filepath.Join(filepath.Dir(o.Home), "ascii-zdotdir")
				o.Components = "shell"
				o.Shells = shell
				o.Runtimes = "none"
				if scenario != "baseline" {
					o.Runtimes = "fnm"
				}
				fakeBin := filepath.Join(o.Home, "fake-bin")
				os.Mkdir(fakeBin, 0700)
				status := "0"
				if scenario == "failed-init" {
					status = "1"
				}
				script := "#!/bin/sh\nprintf '%s\\n' 'export DOTFILES_RUNTIME_INIT=1'\nprintf '%s\\n' 'synthetic unsupported option' >&2\nexit " + status + "\n"
				os.WriteFile(filepath.Join(fakeBin, "fnm"), []byte(script), 0755)
				os.Chmod(filepath.Join(fakeBin, "fnm"), 0755)
				if e = prepareState(o); e != nil {
					t.Fatal(e)
				}
				idx, _ := loadIndex(o)
				if e = install(o, idx, io.Discard); e != nil {
					t.Fatal(e)
				}
				env := []string{"HOME=" + o.Home, "ZDOTDIR=" + o.ZshDir, "PATH=" + fakeBin + string(os.PathListSeparator) + os.Getenv("PATH"), "TERM=xterm-256color", "NO_COLOR=1", "LANG=C.UTF-8", "XDG_CACHE_HOME=" + o.Cache, "XDG_DATA_HOME=" + o.Data, "XDG_CONFIG_HOME=" + o.Config}
				args := []string{"-d", "-ic", "printf '%s\\n' \"${DOTFILES_RUNTIME_INIT:-0}\""}
				if shell == "bash" {
					args = []string{"--noprofile", "--norc", "-ic", ". \"$HOME/.bashrc\"; printf '%s\\n' \"${DOTFILES_RUNTIME_INIT:-0}\""}
				}
				cmd := exec.Command(executable, args...)
				cmd.Env = env
				cmd.Dir = o.Home
				var stderr bytes.Buffer
				cmd.Stderr = &stderr
				b, e := cmd.Output()
				if e != nil {
					t.Fatalf("startup: %v %s", e, stderr.String())
				}
				want := "0"
				if scenario == "opt-in" {
					want = "1"
				}
				if strings.TrimSpace(string(b)) != want {
					t.Fatalf("runtime scenario %s: %q", scenario, b)
				}
				if strings.Contains(stderr.String(), "synthetic") {
					t.Fatal("optional initializer error leaked into startup")
				}
			})
		}
	}
}
