package deploy

import (
	"archive/tar"
	"archive/zip"
	"bytes"
	"compress/gzip"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPinnedAssets(t *testing.T) {
	seen := map[string]bool{}
	for _, a := range assets {
		key := strings.Join([]string{a.Tool, a.OS, a.Arch, a.Libc}, "/")
		if seen[key] {
			t.Fatal("duplicate asset", key)
		}
		seen[key] = true
		if len(a.SHA256) != 64 || !strings.HasPrefix(a.URL, "https://github.com/") || strings.Contains(a.URL, "latest") {
			t.Fatal("unverified asset", key)
		}
		if filepath.IsAbs(a.Member) || strings.Contains(a.Member, "..") {
			t.Fatal("unsafe archive member")
		}
	}
	if _, e := asset("fnm", "linux", "amd64", "musl"); e == nil {
		t.Fatal("pretended glibc fnm runs on musl")
	}
	if _, e := asset("bun", "windows", "arm64", ""); e != nil {
		t.Fatal(e)
	}
}
func TestExtractionOnlyReadsExpectedRegularMember(t *testing.T) {
	var buf bytes.Buffer
	z := zip.NewWriter(&buf)
	w, _ := z.Create("../../escape")
	w.Write([]byte("must not extract"))
	w, _ = z.Create("tool/bin")
	w.Write([]byte("fixture executable"))
	z.Close()
	b, e := extractBinary(buf.Bytes(), Asset{URL: "https://example.invalid/a.zip", Member: "tool/bin"})
	if e != nil || string(b) != "fixture executable" {
		t.Fatal(e)
	}
	buf.Reset()
	gz := gzip.NewWriter(&buf)
	tr := tar.NewWriter(gz)
	tr.WriteHeader(&tar.Header{Name: "./bin", Mode: 0755, Size: 7, Typeflag: tar.TypeReg})
	tr.Write([]byte("fixture"))
	tr.Close()
	gz.Close()
	b, e = extractBinary(buf.Bytes(), Asset{URL: "https://example.invalid/a.tar.gz", Member: "bin"})
	if e != nil || string(b) != "fixture" {
		t.Fatal(e)
	}
	if _, e = extractBinary(buf.Bytes(), Asset{URL: "a.tar.gz", Member: "absent"}); e == nil {
		t.Fatal("accepted missing member")
	}
}
func TestOfflineCacheChecksum(t *testing.T) {
	o := fixture(t)
	o.Toolset = "bun"
	o.TargetOS = "linux"
	o.TargetArch = "amd64"
	o.Libc = "gnu"
	o.Offline = true
	o.DownloadOnly = true
	o.Apply = true
	if e := tools(o, io.Discard); e == nil {
		t.Fatal("offline cache miss accepted")
	}
	a, _ := asset("bun", "linux", "amd64", "gnu")
	cache := filepath.Join(o.Cache, "dotfiles", "archives", a.SHA256)
	os.WriteFile(cache, []byte("corrupt"), 0600)
	if e := tools(o, io.Discard); e == nil || !strings.Contains(e.Error(), "checksum") {
		t.Fatal("corrupt cache accepted", e)
	}
}
func TestPluginExtractionRejectsTraversalAndLinks(t *testing.T) {
	for _, h := range []*tar.Header{{Name: "root/../../escape", Mode: 0644, Size: 1, Typeflag: tar.TypeReg}, {Name: "root/link", Linkname: "/outside", Typeflag: tar.TypeSymlink}} {
		var buf bytes.Buffer
		gz := gzip.NewWriter(&buf)
		tr := tar.NewWriter(gz)
		if e := tr.WriteHeader(h); e != nil {
			t.Fatal(e)
		}
		if h.Size > 0 {
			tr.Write([]byte("x"))
		}
		tr.Close()
		gz.Close()
		if e := extractPlugin(t.TempDir(), buf.Bytes()); e == nil {
			t.Fatal("accepted unsafe plugin archive")
		}
	}
}
func TestPluginDownloadOnlyDoesNotSkipExistingInstallations(t *testing.T) {
	o := fixture(t)
	o.Apply = true
	o.Offline = true
	o.DownloadOnly = true
	for _, p := range pluginSources {
		if e := os.MkdirAll(filepath.Join(o.PluginDir, p.Name), 0700); e != nil {
			t.Fatal(e)
		}
	}
	e := plugins(o, io.Discard)
	if e == nil || !strings.Contains(e.Error(), "offline plugin archive missing") {
		t.Fatalf("existing installation skipped offline archive preparation: %v", e)
	}
}
