package deploy

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// Explicit setup for the three approved plugins, without a startup manager.
var pluginSources = []struct{ Name, URL, SHA256 string }{
	{"fast-syntax-highlighting", "https://codeload.github.com/zdharma-continuum/fast-syntax-highlighting/tar.gz/3d574ccf48804b10dca52625df13da5edae7f553", "20481200fdd23fe15df1e4ff77cfa778b2278cd43786befff9e406c031461ae5"},
	{"zsh-autosuggestions", "https://codeload.github.com/zsh-users/zsh-autosuggestions/tar.gz/85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5", "20665e469e720e674964a66854d5534b9af78cdfd438512746ecd1ade8e819ce"},
	{"zsh-completions", "https://codeload.github.com/zsh-users/zsh-completions/tar.gz/dbaeafd96c3fd9d84c8540f6d87c6b37c4c9173d", "e124c24f16ec0cdbf727aa8d0c76404550454f9bef6d9991f318d526994844ab"},
}

func plugins(o Options, out io.Writer) error {
	if within(o.Repo, o.PluginDir) {
		return errors.New("plugins must be installed outside repository")
	}
	if o.Upgrade {
		return errors.New("plugin updates require explicit revision review and backup of existing plugin directories; see docs/MAINTENANCE.md")
	}
	for _, p := range pluginSources {
		dest := filepath.Join(o.PluginDir, p.Name)
		if e := safeParents(filepath.Join(dest, "placeholder")); e != nil {
			return e
		}
		if info, e := os.Lstat(dest); e == nil {
			if !info.IsDir() {
				return errors.New("existing plugin is not a directory")
			}
			fmt.Fprintf(out, "keep existing\t%s\n", dest)
			continue
		} else if !os.IsNotExist(e) {
			return e
		}
		fmt.Fprintf(out, "prepare plugin\t%s\t%s\n", p.Name, p.URL)
		if !o.Apply {
			continue
		}
		cache := filepath.Join(o.Cache, "dotfiles", "archives")
		var dirs []string
		if e := mkdirTracked(cache, &dirs); e != nil {
			return e
		}
		cachePath := filepath.Join(cache, p.SHA256)
		f, e := fingerprint(cachePath)
		if e != nil {
			return e
		}
		var b []byte
		if f.Kind == "file" {
			b, e = os.ReadFile(cachePath)
		} else if f.Kind == "absent" {
			if o.Offline {
				return fmt.Errorf("offline plugin archive missing: %s", p.Name)
			}
			b, e = fetchArchive(p.URL)
		} else {
			return errors.New("plugin cache must be a regular file")
		}
		if e != nil {
			return e
		}
		if digest(b) != p.SHA256 {
			return errors.New("plugin checksum mismatch")
		}
		if f.Kind == "absent" {
			if e = writeAtomic(cachePath, b, 0600); e != nil {
				return e
			}
		}
		if o.DownloadOnly {
			continue
		}
		if e = mkdirTracked(o.PluginDir, &dirs); e != nil {
			return e
		}
		stage, e := os.MkdirTemp(o.PluginDir, ".dotfiles-plugin-*")
		if e != nil {
			return e
		}
		e = extractPlugin(stage, b)
		if e == nil {
			e = writeAtomic(filepath.Join(stage, ".dotfiles-archive.sha256"), []byte(p.SHA256+"\n"), 0644)
		}
		if e == nil {
			if _, statErr := os.Lstat(dest); !os.IsNotExist(statErr) {
				e = errors.New("plugin appeared during setup")
			}
		}
		if e == nil {
			e = os.Rename(stage, dest)
		}
		os.RemoveAll(stage) // Only the unique staging directory created above.
		if e != nil {
			return e
		}
	}
	return nil
}
func extractPlugin(root string, b []byte) error {
	z, e := gzip.NewReader(bytes.NewReader(b))
	if e != nil {
		return e
	}
	defer z.Close()
	tr := tar.NewReader(z)
	var total int64
	for {
		h, e := tr.Next()
		if e == io.EOF {
			return nil
		}
		if e != nil {
			return e
		}
		parts := strings.SplitN(h.Name, "/", 2)
		if len(parts) < 2 || parts[1] == "" {
			continue
		}
		rel := filepath.FromSlash(parts[1])
		p := filepath.Join(root, rel)
		if filepath.IsAbs(rel) || !within(root, p) || strings.Contains(rel, ":") {
			return errors.New("unsafe plugin archive path")
		}
		if h.Typeflag == tar.TypeDir {
			if e = os.MkdirAll(p, 0755); e != nil {
				return e
			}
			continue
		}
		if h.Typeflag != tar.TypeReg {
			return errors.New("plugin archive contains a link or special file")
		}
		total += h.Size
		if total > 64*1024*1024 || h.Size < 0 {
			return errors.New("plugin archive exceeds size limit")
		}
		if e = os.MkdirAll(filepath.Dir(p), 0755); e != nil {
			return e
		}
		payload, e := io.ReadAll(tr)
		if e != nil {
			return e
		}
		mode := os.FileMode(0644)
		if h.Mode&0111 != 0 {
			mode = 0755
		}
		if e = writeAtomic(p, payload, mode); e != nil {
			return e
		}
	}
}
