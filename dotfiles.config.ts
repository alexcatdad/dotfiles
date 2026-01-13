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
    "shell/functions": ".config/shell/functions",

    // Starship prompt (unified Gruvbox Dark theme)
    "starship/starship.toml": ".config/starship.toml",

    // Git configuration
    "git/gitconfig": ".gitconfig",
    "git/ignore": ".config/git/ignore",

    // NOTE: SSH config NOT managed - too machine-specific (OrbStack, etc.)
    // Users should manually configure ~/.ssh/config

    // Claude Code
    "claude/settings.json": ".claude/settings.json",
    "claude/statusline.sh": ".claude/statusline-command.sh",

    // Terminal emulators
    "terminal/ghostty/config": ".config/ghostty/config",

    // Homebrew
    "homebrew/Brewfile": ".config/homebrew/Brewfile",

    // Ripgrep
    "ripgrep/config": ".config/ripgrep/config",
  },

  // Packages to install
  packages: {
    // Common packages (installed on all platforms via Homebrew/Linuxbrew)
    common: [
      // Prompt
      "starship",     // Cross-shell prompt

      // Modern CLI replacements
      "eza",          // Modern ls replacement
      "fd",           // Modern find replacement
      "ripgrep",      // Fast grep replacement
      "fzf",          // Fuzzy finder
      "zoxide",       // Smarter cd command

      // Utilities
      "jq",           // JSON processor
      "gh",           // GitHub CLI
      "tldr",         // Simplified man pages
      "dust",         // Disk usage analyzer (modern du)
      "btop",         // Modern system monitor
      "direnv",       // Per-directory environment variables
      "fnm",          // Fast Node Manager (replaces nvm)
      "atuin",        // Better shell history with sync
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
    "templates/ssh-config.local.template": ".ssh/config.local",
  },

  // Files/patterns to never overwrite (gitignored, machine-specific)
  ignore: [
    ".zshrc.local",
    ".zshenv.local",
    ".gitconfig.local",
    ".ssh/config.local",
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
      // Make statusline script executable (fail gracefully if symlink wasn't created)
      if (!ctx.dryRun) {
        await ctx.shell("[ -f ~/.claude/statusline-command.sh ] && chmod +x ~/.claude/statusline-command.sh || true");
      }
    },
  },
});
