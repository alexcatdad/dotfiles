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
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()
				cmd := fixtureShellCommand(ctx, shell, executable, args...)
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
func TestDoctorAcceptsRequiredVersionsAndWarnsForOptionalTools(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("native Unix fixture executables")
	}
	o := fixture(t)
	o.Components = "shell"
	o.Shells = "posix"
	bin := filepath.Join(o.Home, "bin")
	os.Mkdir(bin, 0700)
	for name, version := range map[string]string{"jq": "jq-1.7", "go": "go version go1.23.4", "eza": "eza v0.1.0"} {
		p := filepath.Join(bin, name)
		os.WriteFile(p, []byte("#!/bin/sh\necho '"+version+"'\n"), 0755)
		os.Chmod(p, 0755)
	}
	t.Setenv("PATH", bin)
	var out bytes.Buffer
	if e := doctor(o, &out); e != nil {
		t.Fatal(e)
	}
	if !strings.Contains(out.String(), "ok\tjq 1.7") || !strings.Contains(out.String(), "optional incompatible\teza") {
		t.Fatal("required version or optional warning missing")
	}
	os.WriteFile(filepath.Join(bin, "jq"), []byte("#!/bin/sh\necho 'jq-1.3'\n"), 0755)
	if e := doctor(o, io.Discard); e == nil {
		t.Fatal("accepted insufficient required jq version")
	}
}
