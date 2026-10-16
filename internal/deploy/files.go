package deploy

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
)

type Fingerprint struct {
	Kind   string `json:"kind"`
	Hash   string `json:"hash,omitempty"`
	Target string `json:"target,omitempty"`
	Perm   uint32 `json:"perm,omitempty"`
	ACL    string `json:"acl,omitempty"`
}

func digest(b []byte) string { h := sha256.Sum256(b); return hex.EncodeToString(h[:]) }
func owned(i os.FileInfo) bool {
	if runtime.GOOS == "windows" {
		return true
	} // ACL inheritance is checked by Windows, not POSIX mode bits.
	v := reflect.ValueOf(i.Sys())
	if v.Kind() == reflect.Pointer {
		v = v.Elem()
	}
	if v.IsValid() && v.Kind() == reflect.Struct {
		u := v.FieldByName("Uid")
		if u.IsValid() {
			return u.Uint() == uint64(os.Geteuid()) || u.Uint() == 0
		}
	}
	return false
}
func ownedByUser(i os.FileInfo) bool {
	if runtime.GOOS == "windows" {
		return true
	}
	v := reflect.ValueOf(i.Sys())
	if v.Kind() == reflect.Pointer {
		v = v.Elem()
	}
	if v.IsValid() && v.Kind() == reflect.Struct {
		u := v.FieldByName("Uid")
		return u.IsValid() && u.Uint() == uint64(os.Geteuid())
	}
	return false
}
func safeParents(path string) error {
	p := filepath.Dir(path)
	for {
		i, e := os.Lstat(p)
		if e == nil {
			if !i.IsDir() || i.Mode()&os.ModeSymlink != 0 {
				return fmt.Errorf("unsafe parent directory: %s", p)
			}
			// User namespaces may map the system root to an overflow UID. A
			// non-writable filesystem root and sticky shared temp root are valid
			// boundaries; user-controlled parents still require reviewed ownership.
			if !owned(i) && filepath.Dir(p) != p && i.Mode()&os.ModeSticky == 0 {
				return fmt.Errorf("unreviewed parent ownership: %s", p)
			}
			if runtime.GOOS != "windows" && i.Mode().Perm()&0022 != 0 && i.Mode()&os.ModeSticky == 0 {
				return fmt.Errorf("writable parent directory: %s", p)
			}
		} else if !os.IsNotExist(e) {
			return e
		}
		next := filepath.Dir(p)
		if next == p {
			break
		}
		p = next
	}
	return nil
}
func fingerprint(path string) (Fingerprint, error) {
	if err := safeParents(path); err != nil {
		return Fingerprint{}, err
	}
	i, e := os.Lstat(path)
	if os.IsNotExist(e) {
		return Fingerprint{Kind: "absent"}, nil
	}
	if e != nil {
		return Fingerprint{}, e
	}
	if !ownedByUser(i) {
		return Fingerprint{}, fmt.Errorf("unreviewed destination ownership: %s", path)
	}
	if i.Mode()&os.ModeSymlink != 0 {
		target, e := os.Readlink(path)
		return Fingerprint{Kind: "symlink", Target: target}, e
	}
	if !i.Mode().IsRegular() {
		return Fingerprint{}, fmt.Errorf("destination is not a regular file or symlink: %s", path)
	}
	b, e := os.ReadFile(path)
	if e != nil {
		return Fingerprint{}, e
	}
	acl, e := fileACL(path)
	return Fingerprint{Kind: "file", Hash: digest(b), Perm: uint32(i.Mode().Perm()), ACL: acl}, e
}
func desired(c Candidate, o Options) Fingerprint {
	if c.Mode == "symlink" {
		return Fingerprint{Kind: "symlink", Target: filepath.Join(o.Repo, filepath.FromSlash(c.Source))}
	}
	return Fingerprint{Kind: "file", Hash: digest(c.Content), Perm: 0644}
}
func same(a, b Fingerprint) bool {
	if runtime.GOOS == "windows" {
		a.Perm = 0
		b.Perm = 0
	}
	if a.ACL == "" || b.ACL == "" {
		a.ACL = ""
		b.ACL = ""
	} // A not-yet-written candidate inherits its parent's DACL.
	return a == b
}

func writeAtomic(path string, b []byte, perm os.FileMode) error {
	if err := safeParents(path); err != nil {
		return err
	}
	f, e := os.CreateTemp(filepath.Dir(path), ".dotfiles-*")
	if e != nil {
		return e
	}
	tmp := f.Name()
	defer os.Remove(tmp)
	if e = f.Chmod(perm); e == nil {
		_, e = f.Write(b)
	}
	if e == nil {
		e = f.Sync()
	}
	ce := f.Close()
	if e == nil {
		e = ce
	}
	if e != nil {
		return e
	}
	return os.Rename(tmp, path)
}
func writeJSON(path string, v any) error {
	b, e := json.MarshalIndent(v, "", "  ")
	if e != nil {
		return e
	}
	return writeAtomic(path, append(b, '\n'), 0600)
}
func readJSON(path string, v any) error {
	f, e := fingerprint(path)
	if e != nil {
		return e
	}
	if f.Kind != "file" {
		return errors.New("state must be an existing regular file")
	}
	if runtime.GOOS != "windows" && f.Perm&0077 != 0 {
		return errors.New("state file must be private")
	}
	b, e := os.ReadFile(path)
	if e != nil {
		return e
	}
	return json.Unmarshal(b, v)
}

func mkdirTracked(path string, created *[]string) error {
	if e := safeParents(filepath.Join(path, "placeholder")); e != nil {
		return e
	}
	i, e := os.Lstat(path)
	if e == nil {
		if !i.IsDir() {
			return fmt.Errorf("not a directory: %s", path)
		}
		return nil
	}
	if !os.IsNotExist(e) {
		return e
	}
	if e = mkdirTracked(filepath.Dir(path), created); e != nil {
		return e
	}
	if e = os.Mkdir(path, 0700); e != nil {
		return e
	}
	*created = append(*created, path)
	return nil
}
