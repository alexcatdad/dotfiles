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
	userPresent := strings.Contains(stateACL, u.Uid) || strings.HasSuffix(u.Uid, "-500") && strings.Contains(stateACL, ";;;LA)")
	if !strings.HasPrefix(stateACL, "D:P") || !userPresent || strings.Count(stateACL, "(") != 2 {
		t.Fatalf("private state DACL not applied: flags=%q entries=%d", strings.SplitN(stateACL, "(", 2)[0], strings.Count(stateACL, "("))
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
