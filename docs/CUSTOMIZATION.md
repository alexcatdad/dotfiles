# Customization Guide

This guide shows you how to customize these dotfiles to match your personal preferences and workflow without modifying the core files.

## Philosophy

These dotfiles are designed to be:
- **Fork-friendly**: Easy to customize without conflicts
- **Update-safe**: Your customizations won't be overwritten during updates
- **Layered**: Local overrides take precedence over defaults

## Local Override System

The dotfiles support multiple levels of customization through local override files:

```
Priority (highest to lowest):
1. ~/.local-overrides        # Your personal overrides
2. ~/.zshrc.local           # Platform-specific overrides
3. ~/dotfiles/shared/       # Default configurations
```

## Creating Local Overrides

### 1. Shell Customizations

Create `~/.local-overrides` for your personal shell customizations:

```bash
# Create your local overrides file
touch ~/.local-overrides

# Add your customizations
cat << 'EOF' >> ~/.local-overrides
# My Personal Shell Customizations

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias myproject='cd ~/Projects/my-important-project'

# Custom functions
function weather() {
    curl "wttr.in/$1"
}

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Custom environment variables
export EDITOR="code"
export BROWSER="firefox"
export PROJECTS_DIR="$HOME/Projects"

# Custom PATH additions
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
EOF
```

### 2. Platform-Specific Overrides

The system automatically sources platform-specific files:

**macOS overrides** (`~/dotfiles/macos/.zshrc.local`):
```bash
# macOS-specific customizations
alias flush-dns='sudo dscacheutil -flushcache'
alias show-hidden='defaults write com.apple.finder AppleShowAllFiles YES'
alias hide-hidden='defaults write com.apple.finder AppleShowAllFiles NO'

# macOS-specific environment variables
export HOMEBREW_NO_ANALYTICS=1
```

**Ubuntu overrides** (`~/dotfiles/ubuntu/.zshrc.local`):
```bash
# Ubuntu-specific customizations
alias apt-update='sudo apt update && sudo apt upgrade'
alias apt-search='apt search'

# Ubuntu-specific paths
export PATH="/snap/bin:$PATH"
```

## Package Customization

### 1. Custom Package Categories

Create your own package categories by modifying `packages.yaml`:

```yaml
# Add this to packages.yaml
personal_tools:
  description: "My personal development tools"
  priority: 8
  packages:
    - name: my-cli-tool
      macos: my-cli-tool
      ubuntu: my-cli-tool
      description: "My custom CLI tool"
      required: false

    - name: personal-script
      global_npm: my-personal-package
      version_constraint: ">=2.0.0"
      required: false
```

### 2. Skip Packages You Don't Want

Create a `.package-skip` file to exclude specific packages:

```bash
# Create skip list
cat << 'EOF' > ~/.package-skip
# Packages to skip during installation
lazygit
glances
bandwhich
EOF
```

Modify the package installer to respect this file:

```bash
# In your local overrides
skip_package() {
    local package="$1"
    [[ -f ~/.package-skip ]] && grep -q "^$package$" ~/.package-skip
}
```

### 3. Custom Package Installer

Create your own package installer wrapper:

```bash
# Create ~/bin/my-install-packages
#!/bin/bash

# Your custom package logic
MY_PACKAGES=(
    "my-favorite-tool"
    "another-tool"
    "custom-cli"
)

echo "Installing my personal packages..."
for package in "${MY_PACKAGES[@]}"; do
    if command -v brew &>/dev/null; then
        brew install "$package"
    elif command -v apt &>/dev/null; then
        sudo apt install -y "$package"
    fi
done

# Then run the main installer
~/dotfiles/scripts/install-packages-yaml.sh "$@"
```

## IDE and Editor Customization

### 1. VSCode Settings Override

Create local VSCode settings that extend the defaults:

```bash
# Create local VSCode settings
mkdir -p ~/.vscode-local
cat << 'EOF' > ~/.vscode-local/settings.json
{
  "editor.fontSize": 16,
  "editor.fontFamily": "SF Mono, Monaco, monospace",
  "workbench.colorTheme": "Ayu Dark",
  "editor.rulers": [100, 120],

  "extensions.ignoreRecommendations": true,

  // Your personal preferences
  "editor.minimap.enabled": false,
  "breadcrumbs.enabled": false,

  // Language-specific overrides
  "[python]": {
    "editor.tabSize": 4
  }
}
EOF
```

Create a script to merge these with the defaults:

```bash
#!/bin/bash
# ~/bin/merge-vscode-settings

jq -s '.[0] * .[1]' \
   ~/.vscode/settings.json \
   ~/.vscode-local/settings.json \
   > ~/.vscode/settings.merged.json

mv ~/.vscode/settings.merged.json ~/.vscode/settings.json
```

### 2. Cursor AI Customization

Similarly for Cursor:

```bash
mkdir -p ~/.cursor-local
cat << 'EOF' > ~/.cursor-local/settings.json
{
  "cursor.ai.model": "gpt-4",
  "cursor.ai.suggestions.enabled": false,
  "cursor.privacy.enableTelemetry": false,

  // Your AI preferences
  "cursor.chat.defaultModel": "claude-3.5-sonnet",
  "cursor.ai.contextLength": "medium"
}
EOF
```

## Git Customization

### 1. Personal Git Configuration

Add personal Git configs that extend the defaults:

```bash
# Create personal Git config
cat << 'EOF' >> ~/.gitconfig.local
[user]
    name = Your Full Name
    email = your.personal@email.com
    signingkey = YOUR_GPG_KEY_ID

[core]
    editor = code --wait

[merge]
    tool = vscode

[mergetool "vscode"]
    cmd = code --wait $MERGED

[diff]
    tool = vscode

[difftool "vscode"]
    cmd = code --wait --diff $LOCAL $REMOTE

[alias]
    # Your personal aliases
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk

    # Advanced aliases
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    conflicts = diff --name-only --diff-filter=U
EOF

# Include local config in main gitconfig
echo "[include]" >> ~/.gitconfig
echo "    path = ~/.gitconfig.local" >> ~/.gitconfig
```

### 2. Project-Specific Git Configuration

Set up conditional Git configs for different projects:

```bash
# Add to ~/.gitconfig
cat << 'EOF' >> ~/.gitconfig
[includeIf "gitdir:~/Work/"]
    path = ~/.gitconfig.work

[includeIf "gitdir:~/Projects/personal/"]
    path = ~/.gitconfig.personal

[includeIf "gitdir:~/Projects/opensource/"]
    path = ~/.gitconfig.opensource
EOF

# Create work-specific config
cat << 'EOF' > ~/.gitconfig.work
[user]
    email = your.work@company.com

[core]
    sshCommand = "ssh -i ~/.ssh/id_work_rsa"
EOF
```

## Function and Alias Customization

### 1. Override Existing Functions

To modify existing functions, create improved versions in your local overrides:

```bash
# In ~/.local-overrides

# Enhanced version of create-ts-project
create-ts-project() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo "Usage: create-ts-project <project-name>"
        return 1
    fi

    # Call the original function
    command create-ts-project "$project_name"

    # Add your customizations
    cd "$project_name"

    # Install additional packages you always use
    npm install -D @types/lodash lodash
    npm install -D husky lint-staged

    # Set up pre-commit hooks
    npx husky install
    npx husky add .husky/pre-commit "lint-staged"

    # Your custom package.json scripts
    npm pkg set scripts.prepare="husky install"
    npm pkg set scripts.check="tsc --noEmit"

    echo "✨ Added personal customizations!"
}
```

### 2. Add New Project Templates

Extend the init-project function with your own templates:

```bash
# In ~/.project-templates.local

create-my-fullstack-project() {
    local name="$1"
    local pm=$(detect_package_manager)

    # Create a custom fullstack setup
    create-nextjs-project "$name"

    # Add backend setup
    mkdir -p api
    cd api
    create-fastify-ts-project "api"
    cd ..

    # Set up monorepo structure
    cat > package.json << 'EOF'
{
  "name": "my-fullstack-template",
  "private": true,
  "workspaces": [".", "api"],
  "scripts": {
    "dev": "concurrently \"npm run dev --workspace=.\" \"npm run dev --workspace=api\"",
    "build": "npm run build --workspaces",
    "test": "npm test --workspaces"
  }
}
EOF

    $pm install -D concurrently
    echo "🎉 Custom fullstack project created!"
}
```

Then add it to your init-project function:

```bash
# In ~/.local-overrides
# Override the init-project function to add your templates
init-project() {
    local project_type="${1:-typescript}"
    local project_name="$2"

    case "$project_type" in
        "my-fullstack")
            create-my-fullstack-project "$project_name"
            return
            ;;
        # Add other custom templates here
        *)
            # Fall back to the original function
            command init-project "$@"
            ;;
    esac
}
```

## Environment-Specific Customizations

### 1. Work vs Personal Environment

Detect and configure based on environment:

```bash
# In ~/.local-overrides

# Detect work environment
if [[ "$PWD" == */Work/* ]] || [[ "$PWD" == */company-projects/* ]]; then
    export WORK_ENV=true

    # Work-specific aliases
    alias deploy-staging='kubectl apply -f staging/'
    alias logs='kubectl logs -f'
    alias vpn='sudo openconnect corporate-vpn.company.com'

    # Work-specific functions
    function work-project() {
        cd "$HOME/Work/$1"
    }

    # Work-specific prompt additions
    PS1="[WORK] $PS1"
fi

# Personal environment
if [[ "$WORK_ENV" != "true" ]]; then
    # Personal aliases
    alias blog='cd ~/Projects/personal/blog'
    alias dotfiles='cd ~/dotfiles'

    # Personal functions
    function personal-backup() {
        rsync -av ~/Projects/personal/ ~/Backup/personal/
    }
fi
```

### 2. Machine-Specific Configurations

Configure based on the specific machine:

```bash
# In ~/.local-overrides

# Get machine identifier
MACHINE_ID=$(hostname -s)

case "$MACHINE_ID" in
    "work-macbook")
        export PROJECTS_DIR="$HOME/Work"
        alias python="python3.9"
        export PATH="/usr/local/opt/python@3.9/bin:$PATH"
        ;;
    "personal-laptop")
        export PROJECTS_DIR="$HOME/Projects"
        alias python="python3.11"
        # Enable experimental features
        export NODE_OPTIONS="--experimental-modules"
        ;;
    "server-"*)
        # Server-specific config
        export EDITOR="nano"  # Lightweight editor for servers
        alias ll='ls -la --color=auto'
        ;;
esac
```

## Theme and Appearance Customization

### 1. Terminal Theme

Customize your terminal colors and prompt:

```bash
# In ~/.local-overrides

# Custom colors
export LSCOLORS="ExFxBxDxCxegedabagacad"
export CLICOLOR=1

# Custom prompt (if not using Powerlevel10k)
if [[ -z "$ZSH_THEME" ]]; then
    # Simple custom prompt
    PROMPT='%F{blue}%n%f@%F{green}%m%f:%F{yellow}%~%f$ '

    # Add git info
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats ' (%b)'
    setopt PROMPT_SUBST
    PROMPT='%F{blue}%n%f@%F{green}%m%f:%F{yellow}%~%f%F{red}${vcs_info_msg_0_}%f$ '
fi
```

### 2. Modern CLI Tool Themes

Customize themes for modern CLI tools:

```bash
# In ~/.local-overrides

# Custom bat theme
export BAT_THEME="Monokai Extended"

# Custom fzf colors
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --color=bg+:#3c3c3c,spinner:#f92672,hl:#fd971f,fg:#f8f8f2,header:#fd971f,info:#a6e22e,pointer:#f92672,marker:#f92672,fg+:#f8f8f2,prompt:#f92672,hl+:#fd971f"

# Custom exa colors
export EXA_COLORS="da=36:ur=34:uw=35:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36:"
```

## Integration with External Tools

### 1. Docker Integration

Add custom Docker functions and aliases:

```bash
# In ~/.local-overrides

# Docker development helpers
function docker-dev-env() {
    local service="${1:-app}"
    docker-compose exec "$service" /bin/bash
}

function docker-fresh() {
    docker-compose down --volumes --remove-orphans
    docker-compose up --build
}

function docker-cleanup() {
    docker system prune -af
    docker volume prune -f
}

# Project-specific docker aliases
alias myproject-up='docker-compose -f ~/Projects/myproject/docker-compose.yml up -d'
alias myproject-logs='docker-compose -f ~/Projects/myproject/docker-compose.yml logs -f'
```

### 2. Cloud Provider Integration

Add cloud-specific tools and shortcuts:

```bash
# In ~/.local-overrides

# AWS helpers
if command -v aws &>/dev/null; then
    function aws-profile() {
        export AWS_PROFILE="$1"
        echo "Switched to AWS profile: $1"
    }

    function aws-whoami() {
        aws sts get-caller-identity
    }

    # Common aliases
    alias s3ls='aws s3 ls'
    alias ec2ls='aws ec2 describe-instances --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,Name:Tags[?Key==\`Name\`]|[0].Value}"'
fi

# Kubernetes helpers
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'

    function kctx() {
        kubectl config use-context "$1"
    }

    function kns() {
        kubectl config set-context --current --namespace="$1"
    }
fi
```

## Maintenance of Custom Configurations

### 1. Version Control Your Customizations

Keep your customizations in version control:

```bash
# Create a personal config repository
mkdir ~/.dotfiles-personal
cd ~/.dotfiles-personal
git init

# Move your customizations there
mv ~/.local-overrides ./local-overrides
mv ~/.gitconfig.local ./gitconfig.local
mv ~/.vscode-local ./vscode-local

# Create symlinks
ln -sf ~/.dotfiles-personal/local-overrides ~/.local-overrides
ln -sf ~/.dotfiles-personal/gitconfig.local ~/.gitconfig.local
ln -sf ~/.dotfiles-personal/vscode-local ~/.vscode-local

# Commit your customizations
git add .
git commit -m "Initial personal dotfiles customizations"
```

### 2. Update-Safe Customizations

Structure your customizations to survive updates:

```bash
# In ~/.local-overrides
# Use a function to check if updates changed behavior
check_dotfiles_version() {
    local current_version
    if [[ -f ~/dotfiles/.version ]]; then
        current_version=$(cat ~/dotfiles/.version)
    else
        current_version="unknown"
    fi

    # Handle version-specific customizations
    case "$current_version" in
        "2.0"*)
            # Customizations for version 2.0
            ;;
        "1."*)
            # Legacy customizations
            ;;
    esac
}

check_dotfiles_version
```

### 3. Testing Your Customizations

Create a test script for your customizations:

```bash
#!/bin/bash
# ~/.dotfiles-personal/test-customizations.sh

echo "Testing personal customizations..."

# Test custom functions
if command -v weather &>/dev/null; then
    echo "✓ weather function available"
else
    echo "✗ weather function missing"
fi

# Test custom aliases
if alias myproject &>/dev/null; then
    echo "✓ myproject alias available"
else
    echo "✗ myproject alias missing"
fi

# Test environment variables
if [[ -n "$PROJECTS_DIR" ]]; then
    echo "✓ PROJECTS_DIR set to $PROJECTS_DIR"
else
    echo "✗ PROJECTS_DIR not set"
fi

echo "Customization test complete"
```

## Sharing Your Customizations

### 1. Create Installable Customizations

Make your customizations easy to install:

```bash
#!/bin/bash
# ~/.dotfiles-personal/install-my-customizations.sh

set -e

echo "Installing personal dotfiles customizations..."

# Create necessary directories
mkdir -p ~/.vscode-local
mkdir -p ~/.cursor-local

# Install custom functions
cp local-overrides ~/.local-overrides
cp gitconfig.local ~/.gitconfig.local
cp -r vscode-local/* ~/.vscode-local/

# Install custom binaries
mkdir -p ~/bin
cp bin/* ~/bin/
chmod +x ~/bin/*

echo "Personal customizations installed!"
echo "Run 'source ~/.zshrc' to apply changes"
```

### 2. Document Your Customizations

Create documentation for your customizations:

```markdown
# My Personal Dotfiles Customizations

## Custom Functions

- `weather <city>` - Get weather information for a city
- `docker-dev-env [service]` - Enter a Docker development environment
- `work-project <name>` - Switch to a work project

## Custom Aliases

- `myproject` - Quick access to my main project
- `ll` - Enhanced ls with all files and details

## Environment Variables

- `PROJECTS_DIR` - Directory where projects are stored
- `WORK_ENV` - Set to `true` when in work environment

## Installation

```bash
git clone https://github.com/yourusername/dotfiles-personal.git ~/.dotfiles-personal
cd ~/.dotfiles-personal
./install-my-customizations.sh
```

Remember: The key to successful customization is to keep your changes separate from the main dotfiles so you can easily update the core system while preserving your personal preferences.