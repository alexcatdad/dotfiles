/**
 * Dotfiles Configuration
 * Defines symlinks, packages, and templates for dotfiles management
 */

import { defineConfig } from "./src/core/config";

export default defineConfig({
  // Symlink mappings: source (relative to config/) -> target (relative to $HOME)
  symlinks: {
    // Shell configuration
    "shell/zshrc": ".zshrc",
    "shell/zshenv": ".zshenv",

    // Starship prompt (unified Gruvbox Dark theme)
    "starship/starship.toml": ".config/starship.toml",

    // Git configuration
    "git/gitconfig": ".gitconfig",
    "git/ignore": ".config/git/ignore",

    // Claude Code
    "claude/settings.json": ".claude/settings.json",
    "claude/statusline.sh": ".claude/statusline-command.sh",

    // Terminal emulators
    "terminal/ghostty/config": ".config/ghostty/config",
  },

  // Packages to install
  packages: {
    // Common packages (installed on all platforms via Homebrew/Linuxbrew)
    common: [
      "starship",     // Cross-shell prompt
      "eza",          // Modern ls replacement
      "zoxide",       // Smarter cd command
      "fzf",          // Fuzzy finder
      "bat",          // Cat with syntax highlighting
      "fd",           // Modern find replacement
      "ripgrep",      // Fast grep replacement
      "jq",           // JSON processor
      "gh",           // GitHub CLI
    ],

    // macOS-specific packages (casks)
    darwin: [
      "font-fira-code-nerd-font",  // Nerd Font for terminal icons
      "ghostty",                    // Terminal emulator
    ],

    // Linux-specific packages
    linux: {
      // Prerequisites installed via apt
      apt: [
        "build-essential",
        "curl",
        "git",
      ],
      // Additional packages via Linuxbrew
      brew: [],
    },
  },

  // Template files for machine-specific configuration
  templates: {
    "templates/zshrc.local.template": ".zshrc.local",
    "templates/zshenv.local.template": ".zshenv.local",
    "templates/gitconfig.local.template": ".gitconfig.local",
  },

  // Files/patterns to never overwrite (gitignored, machine-specific)
  ignore: [
    ".zshrc.local",
    ".zshenv.local",
    ".gitconfig.local",
    ".claude/settings.local.json",
    ".claude/.credentials.json",
  ],

  // Backup configuration
  backup: {
    enabled: true,
    maxAge: 30,      // Days to keep backups
    maxCount: 5,     // Max backups per file
  },

  // Lifecycle hooks
  hooks: {
    postInstall: async (ctx) => {
      // Make statusline script executable
      if (!ctx.dryRun) {
        await ctx.shell("chmod +x ~/.claude/statusline-command.sh");
      }
    },
  },
});
