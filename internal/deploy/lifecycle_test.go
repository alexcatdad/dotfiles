package deploy

import (
	"bytes"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func fixture(t *testing.T) Options {
	t.Helper()
	root := t.TempDir()
	root, e := filepath.EvalSymlinks(root)
	if e != nil {
		t.Fatal(e)
	}
	o := defaults()
	o.Home = filepath.Join(root, "home with spaces 日本")
	o.Repo = filepath.Join(root, "repo")
	o.Components = "search"
	o.State = filepath.Join(root, "private-state")
	if e = os.MkdirAll(o.Home, 0700); e != nil {
		t.Fatal(e)
	}
	if e = os.MkdirAll(filepath.Join(o.Repo, "home", ".config", "ripgrep"), 0700); e != nil {
		t.Fatal(e)
	}
	if e = os.WriteFile(filepath.Join(o.Repo, "home", ".config", "ripgrep", "config"), []byte("--smart-case\n"), 0644); e != nil {
		t.Fatal(e)
	}
	if e = o.normalize(); e != nil {
		t.Fatal(e)
	}
	return o
}
func invoke(t *testing.T, o Options, command string) error {
	t.Helper()
	var b bytes.Buffer
	args := []string{command, "--repo", o.Repo, "--home", o.Home, "--state-dir", o.State, "--components", o.Components, "--shells", o.Shells, "--config-dir", o.Config, "--zsh-dir", o.ZshDir, "--mode", o.Mode}
	if o.Replace {
		args = append(args, "--replace")
	}
	if o.Apply {
		args = append(args, "--apply")
	}
	return Run(args, &b)
}
func applyFixture(t *testing.T, o Options) Options {
	t.Helper()
	o.Apply = true
	if e := invoke(t, o, "install"); e != nil {
		t.Fatal(e)
	}
	return o
}
func target(o Options) string { return filepath.Join(o.Config, "ripgrep", "config") }
func content(t *testing.T, p string) string {
	t.Helper()
	b, e := os.ReadFile(p)
	if e != nil {
		t.Fatal(e)
	}
	return string(b)
}

func TestPreviewNeverWrites(t *testing.T) {
	o := fixture(t)
	if e := invoke(t, o, "install"); e != nil {
		t.Fatal(e)
	}
	if _, e := os.Lstat(o.State); !os.IsNotExist(e) {
		t.Fatal("preview wrote state")
	}
	if _, e := os.Lstat(o.Config); !os.IsNotExist(e) {
		t.Fatal("preview wrote configuration")
	}
}
func TestInstallRepeatAndUninstall(t *testing.T) {
	o := applyFixture(t, fixture(t))
	p := target(o)
	info, _ := os.Stat(p)
	if e := invoke(t, o, "install"); e != nil {
		t.Fatal(e)
	}
	repeated, _ := os.Stat(p)
	if !info.ModTime().Equal(repeated.ModTime()) {
		t.Fatal("repeat changed timestamp")
	}
	if e := invoke(t, o, "uninstall"); e != nil {
		t.Fatal(e)
	}
	if _, e := os.Lstat(p); !os.IsNotExist(e) {
		t.Fatal("uninstall retained owned file")
	}
	if _, e := os.Lstat(filepath.Dir(p)); !os.IsNotExist(e) {
		t.Fatal("uninstall retained installer-created empty directory")
	}
	if e := invoke(t, o, "rollback"); e != nil {
		t.Fatal("could not undo uninstall", e)
	}
	if content(t, p) != "--smart-case\n" {
		t.Fatal("uninstall rollback failed")
	}
}
func TestConflictBackupRollback(t *testing.T) {
	o := fixture(t)
	if e := os.MkdirAll(filepath.Dir(target(o)), 0700); e != nil {
		t.Fatal(e)
	}
	if e := os.WriteFile(target(o), []byte("original private fixture\n"), 0600); e != nil {
		t.Fatal(e)
	}
	o.Apply = true
	if e := invoke(t, o, "install"); e == nil {
		t.Fatal("overwrote unreviewed conflict")
	}
	o.Replace = true
	o = applyFixture(t, o)
	if e := invoke(t, o, "rollback"); e != nil {
		t.Fatal(e)
	}
	if content(t, target(o)) != "original private fixture\n" {
		t.Fatal("original not restored")
	}
	if runtime.GOOS != "windows" {
		i, _ := os.Stat(target(o))
		if i.Mode().Perm() != 0600 {
			t.Fatal("original permissions lost")
		}
	}
}
func TestDriftRefusesAllMutations(t *testing.T) {
	for _, command := range []string{"install", "uninstall", "rollback", "status"} {
		t.Run(command, func(t *testing.T) {
			o := applyFixture(t, fixture(t))
			os.WriteFile(target(o), []byte("local edit"), 0644)
			if e := invoke(t, o, command); e == nil {
				t.Fatal("accepted drift")
			}
			if content(t, target(o)) != "local edit" {
				t.Fatal("changed drifted file")
			}
		})
	}
}
func TestUpdatesKeepOriginalForUninstall(t *testing.T) {
	o := fixture(t)
	os.MkdirAll(filepath.Dir(target(o)), 0700)
	os.WriteFile(target(o), []byte("before adoption"), 0644)
	o.Replace = true
	o = applyFixture(t, o)
	os.WriteFile(filepath.Join(o.Repo, "home", ".config", "ripgrep", "config"), []byte("candidate v2"), 0644)
	if e := invoke(t, o, "install"); e != nil {
		t.Fatal(e)
	}
	if content(t, target(o)) != "candidate v2" {
		t.Fatal("update failed")
	}
	if e := invoke(t, o, "uninstall"); e != nil {
		t.Fatal(e)
	}
	if content(t, target(o)) != "before adoption" {
		t.Fatal("uninstall restored intermediate version")
	}
}
func TestIdenticalExistingFileIsNeverOwned(t *testing.T) {
	o := fixture(t)
	os.MkdirAll(filepath.Dir(target(o)), 0700)
	os.WriteFile(target(o), []byte("--smart-case\n"), 0644)
	o = applyFixture(t, o)
	if e := invoke(t, o, "uninstall"); e != nil {
		t.Fatal(e)
	}
	if content(t, target(o)) != "--smart-case\n" {
		t.Fatal("deleted unowned identical file")
	}
}
func TestSymlinkOriginalIsNotFollowed(t *testing.T) {
	o := fixture(t)
	os.MkdirAll(filepath.Dir(target(o)), 0700)
	private := filepath.Join(o.Home, "private-fixture")
	os.WriteFile(private, []byte("private"), 0600)
	if e := os.Symlink(private, target(o)); e != nil {
		t.Skip("symlink privileges unavailable")
	}
	o.Replace = true
	o = applyFixture(t, o)
	if content(t, private) != "private" {
		t.Fatal("symlink target modified")
	}
	if e := invoke(t, o, "rollback"); e != nil {
		t.Fatal(e)
	}
	if p, e := os.Readlink(target(o)); e != nil || p != private {
		t.Fatal("original symlink not restored")
	}
}
func TestSymlinkParentRejected(t *testing.T) {
	o := fixture(t)
	elsewhere := filepath.Join(o.Home, "elsewhere")
	os.Mkdir(elsewhere, 0700)
	if e := os.Symlink(elsewhere, o.Config); e != nil {
		t.Skip("symlink privileges unavailable")
	}
	if e := invoke(t, o, "plan"); e == nil {
		t.Fatal("accepted symlink parent")
	}
}
func TestUnsupportedDestinationRejected(t *testing.T) {
	o := fixture(t)
	os.MkdirAll(target(o), 0700)
	if e := invoke(t, o, "plan"); e == nil {
		t.Fatal("accepted directory as file")
	}
}
func TestPermissionDriftIsNotOverwritten(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("POSIX modes; Windows DACLs are checked natively")
	}
	o := applyFixture(t, fixture(t))
	if e := os.Chmod(target(o), 0640); e != nil {
		t.Fatal(e)
	}
	if e := invoke(t, o, "install"); e == nil {
		t.Fatal("overwrote permission drift")
	}
}
func TestStateMustBePrivateAndOutsideRepo(t *testing.T) {
	o := fixture(t)
	o.State = filepath.Join(o.Repo, "state")
	if e := o.normalize(); e == nil {
		t.Fatal("accepted state under repository")
	}
	if runtime.GOOS == "windows" {
		return
	}
	o = fixture(t)
	os.Mkdir(o.State, 0700)
	os.Chmod(o.State, 0755)
	o.Apply = true
	if e := invoke(t, o, "install"); e == nil {
		t.Fatal("accepted public state")
	}
}
func TestLockRefusesConcurrentApply(t *testing.T) {
	o := fixture(t)
	os.MkdirAll(filepath.Join(o.State, "lock"), 0700)
	o.Apply = true
	if e := invoke(t, o, "install"); e == nil {
		t.Fatal("ignored lock")
	}
}
func TestInterruptedWriteRecovery(t *testing.T) {
	o := applyFixture(t, fixture(t))
	idx, e := loadIndex(o)
	if e != nil {
		t.Fatal(e)
	}
	var j Journal
	if e = readJSON(journalPath(o, idx.Last), &j); e != nil {
		t.Fatal(e)
	}
	// Simulate a crash after file rename but before index/Done completion.
	j.Complete = false
	j.Steps[0].Done = false
	writeJSON(journalPath(o, j.ID), j)
	writeJSON(filepath.Join(o.State, "index.json"), j.BeforeIndex)
	writeJSON(filepath.Join(o.State, "pending.json"), j.ID)
	if e = invoke(t, o, "install"); e == nil {
		t.Fatal("accepted interrupted deployment")
	}
	if e = invoke(t, o, "rollback"); e != nil {
		t.Fatal(e)
	}
	if _, e = os.Lstat(target(o)); !os.IsNotExist(e) {
		t.Fatal("interrupted write not reversed")
	}
}
func TestCorruptBackupRefusesBeforeAnyRestore(t *testing.T) {
	o := fixture(t)
	os.MkdirAll(filepath.Dir(target(o)), 0700)
	os.WriteFile(target(o), []byte("original"), 0644)
	o.Replace = true
	o = applyFixture(t, o)
	idx, _ := loadIndex(o)
	os.WriteFile(idx.Active[target(o)].Backup, []byte("corrupt"), 0600)
	if e := invoke(t, o, "rollback"); e == nil {
		t.Fatal("accepted corrupt backup")
	}
	if content(t, target(o)) != "--smart-case\n" {
		t.Fatal("modified live file despite bad backup")
	}
}
func TestSymlinkModeAndRenderedEntrypoints(t *testing.T) {
	o := fixture(t)
	o.Mode = "symlink"
	if e := os.Symlink("unused", filepath.Join(o.Home, "symlink-test")); e != nil {
		t.Skip("symlink privileges unavailable")
	}
	o = applyFixture(t, o)
	if p, e := os.Readlink(target(o)); e != nil || !strings.HasPrefix(p, o.Repo) {
		t.Fatal("symlink mode not applied")
	}
	if e := invoke(t, o, "uninstall"); e != nil {
		t.Fatal(e)
	}
}
func TestSelectionsAndVersionParsing(t *testing.T) {
	for _, s := range []string{"unknown", "shell,shell", "shell,"} {
		if selection(s, "shell") == nil {
			t.Fatal("accepted invalid selection", s)
		}
	}
	for _, v := range []struct{ s, want string }{{"go version go1.23.4 linux/amd64", "1.23.4"}, {"git version 2.43.0.windows.1", "2.43.0."}, {"eza - v0.20.0", "0.20.0"}, {"unversioned", "unknown"}} {
		got := firstVersion(v.s)
		if strings.TrimRight(got, ".") != strings.TrimRight(v.want, ".") {
			t.Fatalf("version %q: %s", v.s, got)
		}
	}
	if atLeast("1.9", "1.23") || !atLeast("2.0", "1.23") || atLeast("unknown", "1.0") {
		t.Fatal("invalid version comparison")
	}
}
func TestActualInventoryAllComponents(t *testing.T) {
	o := fixture(t)
	repo, e := filepath.Abs(filepath.Join("..", ".."))
	if e != nil {
		t.Fatal(e)
	}
	repo, e = filepath.EvalSymlinks(repo)
	if e != nil {
		t.Fatal(e)
	}
	o.Repo = repo
	o.Components = "shell,git,prompt,history,search,terminal,agents,skills,machine"
	o.Shells = "zsh,bash,fish,powershell,posix"
	o.Terminal = "ghostty"
	o.Machine = "machines/mac-studio.zsh"
	o.LFS = true
	o.ZshDir = filepath.Join(o.Home, "zsh custom")
	for _, mode := range []string{"full", "minimal", "ascii"} {
		o.Prompt = mode
		items, e := inventory(o)
		if e != nil {
			t.Fatal(e)
		}
		if len(items) < 30 {
			t.Fatal("incomplete inventory")
		}
	}
	for _, terminal := range []string{"ghostty", "kitty", "alacritty", "wezterm", "windows-terminal"} {
		o.Terminal = terminal
		if _, e := inventory(o); e != nil {
			t.Fatal(e)
		}
	}
}
