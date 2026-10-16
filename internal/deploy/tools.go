package deploy

import (
	"archive/tar"
	"archive/zip"
	"bytes"
	"compress/gzip"
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

type Asset struct{ Tool, OS, Arch, Libc, URL, SHA256, Member string }

func asset(tool, platform, arch, libc string) (Asset, error) {
	for _, a := range assets {
		if a.Tool == tool && a.OS == platform && a.Arch == arch && a.Libc == libc {
			return a, nil
		}
	}
	return Asset{}, fmt.Errorf("no reviewed %s asset for %s/%s/%s; use a native package or reviewed source build", tool, platform, arch, libc)
}
func tools(o Options, out io.Writer) error {
	if e := selection(o.Toolset, "bun", "fnm", "starship", "atuin"); e != nil {
		return e
	}
	libc := o.Libc
	if o.TargetOS == "linux" && libc == "" {
		libc = "gnu"
		matches, _ := filepath.Glob("/lib/ld-musl-*.so.1")
		if len(matches) > 0 {
			libc = "musl"
		}
	}
	if o.TargetOS != "linux" {
		libc = ""
	}
	if o.Apply && !o.DownloadOnly && (o.TargetOS != runtime.GOOS || o.TargetArch != runtime.GOARCH) {
		return errors.New("foreign tool assets may only be cached with --download-only")
	}
	if within(o.Repo, o.Prefix) {
		return errors.New("tool prefix must be outside repository")
	}
	var selected []Asset
	for _, tool := range strings.Split(o.Toolset, ",") {
		a, e := asset(tool, o.TargetOS, o.TargetArch, libc)
		if e != nil {
			return e
		}
		binary := tool
		if o.TargetOS == "windows" {
			binary += ".exe"
		}
		dest := filepath.Join(o.Prefix, binary)
		f, e := fingerprint(dest)
		if e != nil {
			return e
		}
		if f.Kind != "absent" && !o.Upgrade && !o.DownloadOnly {
			fmt.Fprintf(out, "keep existing\t%s\n", dest)
			continue
		}
		if !o.Upgrade && !o.DownloadOnly {
			if _, e = exec.LookPath(binary); e == nil {
				fmt.Fprintf(out, "keep existing PATH tool\t%s\n", binary)
				continue
			}
		}
		if f.Kind == "symlink" && o.Upgrade {
			return errors.New("tool upgrade refuses a symlink; reconcile the package source first")
		}
		fmt.Fprintf(out, "prepare %s\t%s\tsha256:%s\n", tool, a.URL, a.SHA256)
		selected = append(selected, a)
	}
	if !o.Apply {
		return nil
	}
	cache := filepath.Join(o.Cache, "dotfiles", "archives")
	var dirs []string
	if e := mkdirTracked(cache, &dirs); e != nil {
		return e
	}
	// Prepare all artifacts before writing a binary, including in offline mode.
	payloads := map[string][]byte{}
	for _, a := range selected {
		archivePath := filepath.Join(cache, a.SHA256)
		f, e := fingerprint(archivePath)
		if e != nil {
			return e
		}
		var b []byte
		if f.Kind == "file" {
			b, e = os.ReadFile(archivePath)
			if e != nil {
				return e
			}
			if digest(b) != a.SHA256 {
				return errors.New("cached archive checksum mismatch; remove this archive explicitly and retry")
			}
		} else if f.Kind != "absent" {
			return errors.New("archive cache entry must be a regular file")
		} else {
			if o.Offline {
				return fmt.Errorf("offline archive missing for %s", a.Tool)
			}
			b, e = fetchArchive(a.URL)
			if e != nil {
				return e
			}
			if digest(b) != a.SHA256 {
				return fmt.Errorf("download checksum mismatch for %s", a.Tool)
			}
			if e = writeAtomic(archivePath, b, 0600); e != nil {
				return e
			}
		}
		if !o.DownloadOnly {
			payloads[a.Tool], e = extractBinary(b, a)
			if e != nil {
				return e
			}
		}
	}
	if o.DownloadOnly {
		fmt.Fprintln(out, "Verified archives cached.")
		return nil
	}
	if e := mkdirTracked(o.Prefix, &dirs); e != nil {
		return e
	}
	for _, a := range selected {
		name := a.Tool
		if runtime.GOOS == "windows" {
			name += ".exe"
		}
		p := filepath.Join(o.Prefix, name)
		// Dependencies have a separate lifecycle from configuration rollback.
		// Explicit upgrades retain the previous binary alongside the cache.
		f, e := fingerprint(p)
		if e != nil {
			return e
		}
		if f.Kind != "absent" {
			if !o.Upgrade {
				return errors.New("tool appeared during setup; refusing replacement")
			}
			b, e := os.ReadFile(p)
			if e != nil {
				return e
			}
			if e = writeAtomic(filepath.Join(cache, a.Tool+"-previous-"+digest(b)), b, 0600); e != nil {
				return e
			}
		}
		if e = writeAtomic(p, payloads[a.Tool], 0755); e != nil {
			return e
		}
		fmt.Fprintf(out, "installed\t%s\n", p)
	}
	return nil
}
func fetchArchive(url string) ([]byte, error) {
	if !strings.HasPrefix(url, "https://github.com/") && !strings.HasPrefix(url, "https://codeload.github.com/") {
		return nil, errors.New("unreviewed download URL")
	}
	var last error
	for attempt := 0; attempt < 3; attempt++ {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		req, e := http.NewRequestWithContext(ctx, "GET", url, nil)
		if e != nil {
			cancel()
			return nil, e
		}
		// DefaultTransport honors configured proxies; system roots and Go's
		// SSL_CERT_FILE/SSL_CERT_DIR support remain enabled.
		resp, e := http.DefaultClient.Do(req)
		if e == nil {
			if resp.StatusCode == http.StatusOK {
				b, readErr := io.ReadAll(io.LimitReader(resp.Body, 256*1024*1024+1))
				resp.Body.Close()
				cancel()
				if len(b) > 256*1024*1024 {
					return nil, errors.New("archive exceeds size limit")
				}
				return b, readErr
			}
			resp.Body.Close()
			e = fmt.Errorf("archive request returned HTTP %d", resp.StatusCode)
		}
		cancel()
		last = e
	}
	return nil, last
}
func extractBinary(b []byte, a Asset) ([]byte, error) {
	const limit = 512 * 1024 * 1024
	read := func(r io.Reader) ([]byte, error) {
		b, e := io.ReadAll(io.LimitReader(r, limit+1))
		if len(b) > limit {
			return nil, errors.New("binary exceeds size limit")
		}
		return b, e
	}
	if strings.HasSuffix(a.URL, ".zip") {
		z, e := zip.NewReader(bytes.NewReader(b), int64(len(b)))
		if e != nil {
			return nil, e
		}
		for _, f := range z.File {
			if f.Name == a.Member {
				if f.Mode()&os.ModeSymlink != 0 {
					return nil, errors.New("binary archive member is a symlink")
				}
				r, e := f.Open()
				if e != nil {
					return nil, e
				}
				defer r.Close()
				return read(r)
			}
		}
	} else {
		z, e := gzip.NewReader(bytes.NewReader(b))
		if e != nil {
			return nil, e
		}
		defer z.Close()
		tr := tar.NewReader(z)
		for {
			h, e := tr.Next()
			if e == io.EOF {
				break
			}
			if e != nil {
				return nil, e
			}
			if strings.TrimPrefix(h.Name, "./") == a.Member {
				if h.Typeflag != tar.TypeReg {
					return nil, errors.New("binary archive member is not regular")
				}
				return read(tr)
			}
		}
	}
	return nil, fmt.Errorf("expected binary member absent: %s", a.Member)
}
