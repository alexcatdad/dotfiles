//go:build windows

package deploy

import (
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"testing"
)

func TestWindowsPrivateStateAndOriginalDACLRecovery(t *testing.T) {
	o := fixture(t)
	if e := os.MkdirAll(filepath.Dir(target(o)), 0700); e != nil {
		t.Fatal(e)
	}
	if e := os.WriteFile(target(o), []byte("original ACL fixture"), 0600); e != nil {
		t.Fatal(e)
	}
	u, e := user.Current()
	if e != nil {
		t.Fatal(e)
	}
	if e = restoreACL(target(o), "D:P(A;;FA;;;"+u.Uid+")(A;;FR;;;SY)"); e != nil {
		t.Fatal(e)
	}
	original, e := fileACL(target(o))
	if e != nil {
		t.Fatal(e)
	}
	o.Replace = true
	o = applyFixture(t, o)
	stateACL, e := fileACL(o.State)
	if e != nil {
		t.Fatal(e)
	}
	if !strings.HasPrefix(stateACL, "D:P") || !strings.Contains(stateACL, u.Uid) {
		t.Fatal("private state DACL not applied")
	}
	if e = invoke(t, o, "rollback"); e != nil {
		t.Fatal(e)
	}
	restored, e := fileACL(target(o))
	if e != nil {
		t.Fatal(e)
	}
	if original != restored {
		t.Fatal("original DACL was not restored")
	}
}
