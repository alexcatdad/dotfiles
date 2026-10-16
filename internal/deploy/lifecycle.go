package deploy

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"time"
)

type Record struct {
	Original Fingerprint `json:"original"`
	Backup   string      `json:"backup,omitempty"`
	Deployed Fingerprint `json:"deployed"`
}
type Index struct {
	Version     int               `json:"version"`
	Last        string            `json:"last,omitempty"`
	Active      map[string]Record `json:"active"`
	Directories []string          `json:"directories,omitempty"`
}
type Step struct {
	Destination   string `json:"destination"`
	Before, After Fingerprint
	Backup        string `json:"backup,omitempty"`
	Done          bool   `json:"done"`
	Content       []byte `json:"-"`
}
type Journal struct {
	Version                 int `json:"version"`
	ID, Action              string
	BeforeIndex, AfterIndex Index
	Steps                   []Step
	Directories             []string
	UnconfirmedDirectories  []string
	Complete                bool
}
type Preview struct {
	Source, Destination, Action, Reason string
}

func Run(args []string, out io.Writer) error {
	if len(args) == 0 || member(args[0], "help", "--help", "-h") {
		fmt.Fprintln(out, "dotfiles plan|install|status|rollback|uninstall|doctor|packages|tools|plugins [options]\nAll writes require --apply. Run a command with --help for flags.\nBuild: GOTOOLCHAIN=local go build -o dotfiles ./cmd/dotfiles")
		return nil
	}
	command := args[0]
	if !member(command, "plan", "install", "status", "rollback", "uninstall", "doctor", "packages", "tools", "plugins") {
		return errors.New("unknown command")
	}
	o, e := parse(args[1:], out)
	if errors.Is(e, flag.ErrHelp) {
		return nil
	}
	if e != nil {
		return e
	}
	if command == "doctor" {
		return doctor(o, out)
	}
	if command == "packages" {
		return packages(o, out)
	}
	if command == "tools" {
		return tools(o, out)
	}
	if command == "plugins" {
		return plugins(o, out)
	}
	if command == "plan" || command == "status" || !o.Apply {
		return preview(command, o, out)
	}
	if e = prepareState(o); e != nil {
		return e
	}
	lock := filepath.Join(o.State, "lock")
	if e = os.Mkdir(lock, 0700); e != nil {
		return fmt.Errorf("deployment locked; inspect the existing lock before manual recovery: %w", e)
	}
	defer os.Remove(lock)
	if command == "rollback" {
		return rollback(o, out)
	}
	idx, e := loadIndex(o)
	if e != nil {
		return e
	}
	if pending(o) != "" {
		return errors.New("interrupted transaction exists; inspect and run rollback --apply first")
	}
	if command == "uninstall" {
		return uninstall(o, idx, out)
	}
	return install(o, idx, out)
}

func loadIndex(o Options) (Index, error) {
	i := Index{Version: 1, Active: map[string]Record{}}
	p := filepath.Join(o.State, "index.json")
	if _, e := os.Lstat(p); os.IsNotExist(e) {
		return i, nil
	}
	if e := readJSON(p, &i); e != nil {
		return i, e
	}
	if i.Version != 1 || i.Active == nil {
		return i, errors.New("unsupported or corrupt deployment index")
	}
	return i, nil
}
func pending(o Options) string {
	var id string
	p := filepath.Join(o.State, "pending.json")
	if _, e := os.Lstat(p); os.IsNotExist(e) {
		return ""
	}
	if e := readJSON(p, &id); e != nil {
		return "invalid"
	}
	return id
}
func clone(i Index) Index {
	r := Index{Version: 1, Last: i.Last, Active: map[string]Record{}, Directories: append([]string{}, i.Directories...)}
	for k, v := range i.Active {
		r.Active[k] = v
	}
	return r
}
func prepareState(o Options) error {
	var dirs []string
	if e := mkdirTracked(o.State, &dirs); e != nil {
		return e
	}
	i, e := os.Lstat(o.State)
	if e != nil {
		return e
	}
	if !ownedByUser(i) {
		return errors.New("deployment state must belong to the invoking user")
	}
	if runtime.GOOS != "windows" && i.Mode().Perm()&0077 != 0 {
		return errors.New("deployment state directory must have mode 0700 (or private Windows ACLs)")
	}
	return privateState(o.State)
}
func preview(command string, o Options, out io.Writer) error {
	idx, e := loadIndex(o)
	if e != nil {
		return e
	}
	if id := pending(o); id != "" && command != "rollback" {
		return fmt.Errorf("interrupted transaction %s; inspect private state and use rollback --apply", id)
	}
	if command == "rollback" {
		id := pending(o)
		if id == "" {
			id = idx.Last
		}
		if !validID(id) {
			return errors.New("no valid transaction to roll back")
		}
		var j Journal
		if e = readJSON(journalPath(o, id), &j); e != nil {
			return e
		}
		for _, s := range j.Steps {
			fmt.Fprintf(out, "restore\t%s\n", s.Destination)
		}
		return nil
	}
	if command == "uninstall" {
		for _, p := range sortedKeys(idx.Active) {
			fmt.Fprintf(out, "restore original\t%s\n", p)
		}
		return nil
	}
	items, e := inventory(o)
	if e != nil {
		return e
	}
	conflicts := 0
	for _, c := range items {
		p, e := assess(c, o, idx)
		if e != nil {
			return e
		}
		fmt.Fprintf(out, "%s\t%s\t%s\n", p.Action, p.Destination, p.Reason)
		if p.Action == "conflict" {
			conflicts++
		}
	}
	// status checks all owned files, including components omitted from this invocation.
	if command == "status" {
		for _, p := range sortedKeys(idx.Active) {
			f, e := fingerprint(p)
			if e != nil {
				return e
			}
			if !same(f, idx.Active[p].Deployed) {
				fmt.Fprintf(out, "drift\t%s\n", p)
				conflicts++
			}
		}
	}
	if conflicts > 0 {
		return fmt.Errorf("%d conflicts or drifted files; no files changed", conflicts)
	}
	return nil
}
func assess(c Candidate, o Options, idx Index) (Preview, error) {
	f, e := fingerprint(c.Destination)
	if e != nil {
		return Preview{}, e
	}
	p := Preview{Source: c.Source, Destination: c.Destination, Action: "create"}
	if r, ok := idx.Active[c.Destination]; ok && !same(f, r.Deployed) {
		p.Action = "conflict"
		p.Reason = "local drift; reconcile before updating"
		return p, nil
	}
	want := desired(c, o)
	if same(f, want) || f.Kind == "file" && want.Kind == "file" && f.Hash == want.Hash {
		p.Action = "unchanged"
		return p, nil
	}
	if f.Kind != "absent" {
		if _, ok := idx.Active[c.Destination]; ok {
			p.Action = "update"
		} else if o.Replace {
			p.Action = "replace"
			p.Reason = "original will be backed up"
		} else {
			p.Action = "conflict"
			p.Reason = "review existing file; --replace permits backed-up adoption"
		}
	}
	return p, nil
}
func install(o Options, idx Index, out io.Writer) error {
	items, e := inventory(o)
	if e != nil {
		return e
	}
	j := Journal{Version: 1, Action: "install", BeforeIndex: clone(idx), AfterIndex: clone(idx)}
	for _, c := range items {
		p, e := assess(c, o, idx)
		if e != nil {
			return e
		}
		if p.Action == "conflict" {
			return fmt.Errorf("conflict at %s: %s", p.Destination, p.Reason)
		}
		if p.Action == "unchanged" {
			continue
		}
		before, e := fingerprint(c.Destination)
		if e != nil {
			return e
		}
		j.Steps = append(j.Steps, Step{Destination: c.Destination, Before: before, After: desired(c, o), Content: c.Content})
	}
	if len(j.Steps) == 0 {
		fmt.Fprintln(out, "No changes.")
		return nil
	}
	return transact(o, &j, out)
}
func uninstall(o Options, idx Index, out io.Writer) error {
	j := Journal{Version: 1, Action: "uninstall", BeforeIndex: clone(idx), AfterIndex: clone(idx)}
	j.AfterIndex.Directories = nil
	for _, p := range sortedKeys(idx.Active) {
		r := idx.Active[p]
		f, e := fingerprint(p)
		if e != nil {
			return e
		}
		if !same(f, r.Deployed) {
			return fmt.Errorf("local drift at %s; refusing uninstall", p)
		}
		var content []byte
		if r.Original.Kind == "file" {
			content, e = os.ReadFile(r.Backup)
			if e != nil {
				return e
			}
			if digest(content) != r.Original.Hash {
				return errors.New("original backup hash mismatch")
			}
		}
		j.Steps = append(j.Steps, Step{Destination: p, Before: f, After: r.Original, Content: content})
		delete(j.AfterIndex.Active, p)
	}
	if len(j.Steps) == 0 {
		fmt.Fprintln(out, "No owned files to uninstall.")
		return nil
	}
	return transact(o, &j, out)
}
func newID() string {
	var b [8]byte
	_, e := rand.Read(b[:])
	if e != nil {
		panic(e)
	}
	return time.Now().UTC().Format("20060102T150405Z") + "-" + hex.EncodeToString(b[:])
}
func journalPath(o Options, id string) string {
	return filepath.Join(o.State, "transactions", id, "journal.json")
}
func validID(id string) bool {
	return id != "" && filepath.Base(id) == id && !strings.ContainsAny(id, "/\\") && id != "." && id != ".."
}

func transact(o Options, j *Journal, out io.Writer) error {
	j.ID = newID()
	j.AfterIndex.Last = j.ID
	root := filepath.Dir(journalPath(o, j.ID))
	var dirs []string
	if e := mkdirTracked(root, &dirs); e != nil {
		return e
	}
	// Back up all regular originals before the first live write. Symlink objects
	// are recorded without following their potentially private targets.
	for n := range j.Steps {
		s := &j.Steps[n]
		if s.Before.Kind == "file" {
			b, e := os.ReadFile(s.Destination)
			if e != nil {
				return e
			}
			if digest(b) != s.Before.Hash {
				return errors.New("destination changed during backup")
			}
			s.Backup = filepath.Join(root, fmt.Sprintf("%04d.before", n))
			if e = writeAtomic(s.Backup, b, 0600); e != nil {
				return e
			}
		}
		if j.Action == "install" {
			r, ok := j.AfterIndex.Active[s.Destination]
			if !ok {
				r = Record{Original: s.Before, Backup: s.Backup}
			}
			r.Deployed = s.After
			j.AfterIndex.Active[s.Destination] = r
		}
	}
	if e := writeJSON(journalPath(o, j.ID), j); e != nil {
		return e
	}
	if e := writeJSON(filepath.Join(o.State, "pending.json"), j.ID); e != nil {
		return e
	}
	for n := range j.Steps {
		s := &j.Steps[n]
		f, e := fingerprint(s.Destination)
		if e != nil {
			return e
		}
		if !same(f, s.Before) {
			return fmt.Errorf("concurrent change at %s; transaction retained for rollback", s.Destination)
		}
		// Planned creation is not proof of ownership: another process may create
		// a directory before mkdir. Only confirmed creations may be removed.
		missing := missingDirs(filepath.Dir(s.Destination))
		j.UnconfirmedDirectories = missing
		if e = writeJSON(journalPath(o, j.ID), j); e != nil {
			return e
		}
		var made []string
		if e = mkdirTracked(filepath.Dir(s.Destination), &made); e != nil {
			return e
		}
		j.Directories = append(j.Directories, made...)
		if j.Action == "install" {
			j.AfterIndex.Directories = append(j.AfterIndex.Directories, made...)
		}
		j.UnconfirmedDirectories = nil
		if e = writeJSON(journalPath(o, j.ID), j); e != nil {
			return e
		}
		if e = put(s.Destination, s.After, s.Content); e != nil {
			return fmt.Errorf("write failed; run rollback --apply: %w", e)
		}
		// Capture the actual inherited ACL so later ACL drift is detected too.
		actual, e := fingerprint(s.Destination)
		if e != nil {
			return e
		}
		if !same(actual, s.After) {
			return errors.New("written file failed verification")
		}
		s.After = actual
		if j.Action == "install" {
			r := j.AfterIndex.Active[s.Destination]
			r.Deployed = actual
			j.AfterIndex.Active[s.Destination] = r
		}
		s.Done = true
		if e = writeJSON(journalPath(o, j.ID), j); e != nil {
			return e
		}
	}
	if e := writeJSON(filepath.Join(o.State, "index.json"), j.AfterIndex); e != nil {
		return e
	}
	j.Complete = true
	if e := writeJSON(journalPath(o, j.ID), j); e != nil {
		return e
	}
	if e := os.Remove(filepath.Join(o.State, "pending.json")); e != nil {
		return e
	}
	if j.Action == "uninstall" {
		for n := len(j.BeforeIndex.Directories) - 1; n >= 0; n-- {
			p := j.BeforeIndex.Directories[n]
			removeEmptyDirectory(p)
		}
	}
	fmt.Fprintf(out, "%s: %d files; transaction %s\n", j.Action, len(j.Steps), j.ID)
	return nil
}

func put(path string, f Fingerprint, content []byte) error {
	if e := safeParents(path); e != nil {
		return e
	}
	switch f.Kind {
	case "absent":
		return os.Remove(path)
	case "file":
		if digest(content) != f.Hash {
			return errors.New("payload hash mismatch")
		}
		if e := writeAtomic(path, content, os.FileMode(f.Perm)); e != nil {
			return e
		}
		return restoreACL(path, f.ACL)
	case "symlink":
		p, e := os.CreateTemp(filepath.Dir(path), ".dotfiles-link-*")
		if e != nil {
			return e
		}
		tmp := p.Name()
		p.Close()
		os.Remove(tmp)
		defer os.Remove(tmp)
		if e = os.Symlink(f.Target, tmp); e != nil {
			return e
		}
		return os.Rename(tmp, path)
	}
	return errors.New("unknown file kind")
}
func missingDirs(p string) []string {
	var paths []string
	for {
		if _, e := os.Lstat(p); e == nil {
			break
		}
		paths = append(paths, p)
		next := filepath.Dir(p)
		if next == p {
			break
		}
		p = next
	}
	for i, j := 0, len(paths)-1; i < j; i, j = i+1, j-1 {
		paths[i], paths[j] = paths[j], paths[i]
	}
	return paths
}
func rollback(o Options, out io.Writer) error {
	idx, e := loadIndex(o)
	if e != nil {
		return e
	}
	id := pending(o)
	if id == "" {
		id = idx.Last
	}
	if !validID(id) {
		return errors.New("no valid transaction to roll back")
	}
	var j Journal
	if e = readJSON(journalPath(o, id), &j); e != nil {
		return e
	}
	if j.Version != 1 || j.ID != id {
		return errors.New("unsupported journal")
	}
	// Validate every step and backup before restoring anything.
	for _, s := range j.Steps {
		f, e := fingerprint(s.Destination)
		if e != nil {
			return e
		}
		if !same(f, s.After) && !same(f, s.Before) {
			return fmt.Errorf("local drift at %s; refusing rollback", s.Destination)
		}
		if s.Before.Kind == "file" {
			b, e := os.ReadFile(s.Backup)
			if e != nil {
				return e
			}
			if digest(b) != s.Before.Hash {
				return errors.New("backup hash mismatch")
			}
		}
	}
	// Mark rollback pending too, so interruption can be resumed safely.
	if e = writeJSON(filepath.Join(o.State, "pending.json"), id); e != nil {
		return e
	}
	for n := len(j.Steps) - 1; n >= 0; n-- {
		s := j.Steps[n]
		f, e := fingerprint(s.Destination)
		if e != nil {
			return e
		}
		if same(f, s.Before) {
			continue
		}
		if !same(f, s.After) {
			return errors.New("concurrent change during rollback")
		}
		var b []byte
		if s.Before.Kind == "file" {
			b, e = os.ReadFile(s.Backup)
			if e != nil {
				return e
			}
		}
		var made []string
		if s.Before.Kind != "absent" {
			if e = mkdirTracked(filepath.Dir(s.Destination), &made); e != nil {
				return e
			}
		}
		if e = put(s.Destination, s.Before, b); e != nil {
			return e
		}
	}
	if e = writeJSON(filepath.Join(o.State, "index.json"), j.BeforeIndex); e != nil {
		return e
	}
	for n := len(j.Directories) - 1; n >= 0; n-- {
		removeEmptyDirectory(j.Directories[n])
	} // Only empty directories can be removed.
	if e = os.Remove(filepath.Join(o.State, "pending.json")); e != nil {
		return e
	}
	fmt.Fprintf(out, "Rolled back transaction %s. Private backups retained.\n", id)
	if len(j.UnconfirmedDirectories) > 0 {
		fmt.Fprintln(out, "Unconfirmed directory creations retained for review in the private journal.")
	}
	return nil
}
func removeEmptyDirectory(path string) {
	if safeParents(path) != nil {
		return
	}
	i, e := os.Lstat(path)
	if e == nil && i.IsDir() && i.Mode()&os.ModeSymlink == 0 && ownedByUser(i) {
		_ = os.Remove(path)
	}
}
func sortedKeys(m map[string]Record) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
