package deploy

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

// An explicit inventory is intentionally used instead of a configuration DSL.
type Candidate struct {
	Source      string `json:"source"`
	Destination string `json:"destination"`
	Mode        string `json:"mode"`
	Content     []byte `json:"-"`
}

func quoteSH(s string) string  { return "'" + strings.ReplaceAll(s, "'", "'\"'\"'") + "'" }
func quotePS(s string) string  { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }
func gitQuote(s string) string { b, _ := json.Marshal(filepath.ToSlash(s)); return string(b) }

func inventory(o Options) ([]Candidate, error) {
	var items []Candidate
	add := func(src, dst string, render bool) error {
		p := filepath.Join(o.Repo, filepath.FromSlash(src))
		if !within(o.Repo, p) {
			return fmt.Errorf("source outside repository: %s", src)
		}
		if err := safeParents(p); err != nil {
			return err
		}
		info, err := os.Lstat(p)
		if err != nil {
			return err
		}
		if !info.Mode().IsRegular() {
			return fmt.Errorf("source must be a regular file: %s", src)
		}
		b, err := os.ReadFile(p)
		if err != nil {
			return err
		}
		mode := o.Mode
		if render {
			mode = "copy"
			s := string(b)
			if strings.HasSuffix(src, ".ps1") {
				s = "$env:DOTFILES_CONFIG_HOME = " + quotePS(o.Config) + "\n$env:DOTFILES_DATA_HOME = " + quotePS(o.Data) + "\n$env:DOTFILES_PROFILE = " + quotePS(o.Profile) + "\n" + s
			} else if strings.HasSuffix(src, ".fish") {
				s = "set -gx DOTFILES_CONFIG_HOME " + quoteSH(o.Config) + "\nset -gx DOTFILES_DATA_HOME " + quoteSH(o.Data) + "\nset -gx DOTFILES_PROFILE " + quoteSH(o.Profile) + "\n" + s
			} else if src == "home/.gitconfig" {
				s = strings.ReplaceAll(s, "excludesFile = ~/.config/git/ignore", "excludesFile = "+gitQuote(filepath.Join(o.Config, "git", "ignore")))
				if o.LFS {
					s += "\n[include]\n    path = " + gitQuote(filepath.Join(o.Config, "git", "lfs.gitconfig")) + "\n"
				}
			} else {
				s = "export DOTFILES_CONFIG_HOME=" + quoteSH(o.Config) + "\nexport DOTFILES_DATA_HOME=" + quoteSH(o.Data) + "\nexport DOTFILES_PROFILE=" + quoteSH(o.Profile) + "\n" + s
			}
			b = []byte(s)
			if src != "home/.gitconfig" {
				if strings.HasSuffix(src, ".ps1") {
					b = append([]byte("$env:DOTFILES_RUNTIMES = "+quotePS(o.Runtimes)+"\n"), b...)
				} else if strings.HasSuffix(src, ".fish") {
					b = append([]byte("set -gx DOTFILES_RUNTIMES "+quoteSH(o.Runtimes)+"\n"), b...)
				} else {
					b = append([]byte("export DOTFILES_RUNTIMES="+quoteSH(o.Runtimes)+"\n"), b...)
				}
			}
		}
		items = append(items, Candidate{src, dst, mode, b})
		return nil
	}
	addConfig := func(src, dst string) error {
		return add("home/.config/"+src, filepath.Join(o.Config, filepath.FromSlash(dst)), false)
	}
	if has(o.Components, "shell") {
		if err := addConfig("shell/capabilities.sh", "shell/capabilities.sh"); err != nil {
			return nil, err
		}
		for _, shell := range strings.Split(o.Shells, ",") {
			switch shell {
			case "zsh":
				for _, f := range []string{"path.zsh", "aliases.zsh", "functions.zsh", "plugins.zsh", "alias-tips.zsh"} {
					if err := addConfig("shell/"+f, "shell/"+f); err != nil {
						return nil, err
					}
				}
				for _, f := range []string{".zshenv", ".zprofile", ".zshrc"} {
					if err := add("home/"+f, filepath.Join(o.ZshDir, f), true); err != nil {
						return nil, err
					}
				}
				if filepath.Clean(o.ZshDir) != o.Home {
					bootstrap := "export ZDOTDIR=" + quoteSH(o.ZshDir) + "\n[ ! -r \"$ZDOTDIR/.zshenv\" ] || . \"$ZDOTDIR/.zshenv\"\n"
					items = append(items, Candidate{"generated:ZDOTDIR", filepath.Join(o.Home, ".zshenv"), "copy", []byte(bootstrap)})
				}
			case "bash":
				for _, f := range []string{".bashrc", ".bash_profile"} {
					if err := add("home/"+f, filepath.Join(o.Home, f), true); err != nil {
						return nil, err
					}
				}
				for _, f := range []string{"env.sh", "interactive.bash"} {
					if err := addConfig("shell/"+f, "shell/"+f); err != nil {
						return nil, err
					}
				}
			case "posix":
				if err := add("home/.profile", filepath.Join(o.Home, ".profile"), true); err != nil {
					return nil, err
				}
				if err := addConfig("shell/env.sh", "shell/env.sh"); err != nil {
					return nil, err
				}
			case "fish":
				if err := add("home/.config/fish/conf.d/dotfiles.fish", filepath.Join(o.Config, "fish", "conf.d", "dotfiles.fish"), true); err != nil {
					return nil, err
				}
			case "powershell":
				if err := add("home/.config/powershell/profile.ps1", o.PowerShellProfile, true); err != nil {
					return nil, err
				}
			}
		}
	}
	if has(o.Components, "git") {
		if err := add("home/.gitconfig", filepath.Join(o.Home, ".gitconfig"), true); err != nil {
			return nil, err
		}
		if err := addConfig("git/ignore", "git/ignore"); err != nil {
			return nil, err
		}
		if o.LFS {
			if err := addConfig("git/lfs.gitconfig", "git/lfs.gitconfig"); err != nil {
				return nil, err
			}
		}
	}
	for _, v := range []struct{ component, src, dst string }{
		{"prompt", "starship.toml", "starship.toml"}, {"history", "atuin/config.toml", "atuin/config.toml"}, {"search", "ripgrep/config", "ripgrep/config"},
	} {
		if has(o.Components, v.component) {
			src := v.src
			if v.component == "prompt" && (o.Prompt != "full" || o.Profile == "minimal" || o.Profile == "container") {
				variant := o.Prompt
				if variant == "full" {
					variant = "minimal"
				}
				src = "starship/" + variant + ".toml"
			}
			if err := addConfig(src, v.dst); err != nil {
				return nil, err
			}
		}
	}
	if has(o.Components, "terminal") {
		files := map[string]string{"ghostty": "ghostty/config", "kitty": "kitty/kitty.conf", "alacritty": "alacritty/alacritty.toml", "wezterm": "wezterm/wezterm.lua", "windows-terminal": "windows-terminal/settings.json"}
		if err := addConfig(files[o.Terminal], files[o.Terminal]); err != nil {
			return nil, err
		}
		if o.Terminal == "ghostty" && runtime.GOOS == "darwin" {
			if err := addConfig("ghostty/platforms/macos.conf", "ghostty/platform.conf"); err != nil {
				return nil, err
			}
		}
		// Windows Terminal settings are a mergeable reference. Its live application
		// package directory is never silently replaced by this inventory.
	}
	if has(o.Components, "agents") {
		if err := add("home/.codex/AGENTS.md", filepath.Join(o.Home, ".codex", "AGENTS.md"), false); err != nil {
			return nil, err
		}
	}
	if has(o.Components, "skills") {
		for _, f := range []string{"scratchpad-memory/SKILL.md", "personal-ledger/SKILL.md", "personal-ledger/agents/openai.yaml", "personal-ledger/references/statements.md", "personal-ledger/references/evidence.md"} {
			if err := add("home/.agents/skills/"+f, filepath.Join(o.Home, ".agents", "skills", filepath.FromSlash(f)), false); err != nil {
				return nil, err
			}
		}
	}
	if has(o.Components, "machine") {
		p := filepath.Clean(o.Machine)
		if !within("machines", p) {
			return nil, fmt.Errorf("machine must name a reviewed file under machines/")
		}
		if err := add(filepath.ToSlash(p), filepath.Join(o.Config, "shell", "machine.zsh"), false); err != nil {
			return nil, err
		}
	}
	// Multiple shells can share a dependency; conflicting destinations are errors.
	unique := []Candidate{}
	seen := map[string]Candidate{}
	for _, c := range items {
		key := filepath.Clean(c.Destination)
		if runtime.GOOS == "windows" {
			key = strings.ToLower(key)
		}
		if within(o.State, c.Destination) || within(o.Repo, c.Destination) {
			return nil, fmt.Errorf("destination overlaps repository or state: %s", c.Destination)
		}
		if old, ok := seen[key]; ok {
			if old.Source != c.Source {
				return nil, fmt.Errorf("conflicting destination: %s", c.Destination)
			}
			continue
		}
		seen[key] = c
		unique = append(unique, c)
	}
	return unique, nil
}
