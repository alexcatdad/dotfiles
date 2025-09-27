# Shared Zsh Configuration
# Works across macOS and Ubuntu

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme - powerlevel10k for better performance and features
# Fallback to robbyrussell if p10k not available
if [[ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
else
    ZSH_THEME="robbyrussell"
fi

# Plugins - organized by category
plugins=(
    # Core Oh My Zsh plugins
    git
    gitignore
    history
    sudo

    # Node.js & TypeScript development
    node
    npm
    yarn
    nvm

    # Docker & Infrastructure
    docker
    docker-compose

    # Productivity
    extract
    z
    web-search
    copypath
    copyfile

    # External plugins (install separately)
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

# Plugin configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Performance optimizations
DISABLE_AUTO_UPDATE="false"
DISABLE_UPDATE_PROMPT="false"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Environment Variables
export EDITOR="cursor"
export VISUAL="cursor"
export BROWSER="open"

# Node.js and TypeScript Development
export NODE_OPTIONS="--max-old-space-size=4096"
export NPM_CONFIG_INIT_LICENSE="MIT"
export NPM_CONFIG_INIT_VERSION="0.1.0"

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git Aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline'
alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

# Node.js/TypeScript Aliases
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias ns='npm start'
alias nt='npm test'
alias nr='npm run'
alias nb='npm run build'
alias nw='npm run watch'
alias nd='npm run dev'

# Bun Aliases
alias bi='bun install'
alias bs='bun start'
alias bt='bun test'
alias br='bun run'
alias bb='bun run build'
alias bd='bun run dev'

# Docker Aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker system prune -f'

# Development Shortcuts
alias code='cursor'
alias c='cursor .'
alias reload='source ~/.zshrc'
alias editrc='cursor ~/.zshrc'

# Quick Navigation
alias projects='cd ~/Projects'
alias downloads='cd ~/Downloads'
alias desktop='cd ~/Desktop'

# Utility Functions
function mkcd() {
    mkdir -p "$@" && cd "$_"
}

function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Git utility functions
function gcm() {
    git add . && git commit -m "$1"
}

function gacmp() {
    git add . && git commit -m "$1" && git push
}

# TypeScript project initialization
function init-ts() {
    npm init -y
    npm install -D typescript @types/node ts-node nodemon
    mkdir src
    echo 'console.log("Hello TypeScript!");' > src/index.ts
    npx tsc --init
    echo "TypeScript project initialized!"
}

# Find and kill process by port
function killport() {
    lsof -ti:$1 | xargs kill -9
}

# Performance: Load files conditionally and cache results
zsh_load_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        source "$file"
    fi
}

# Load configuration files
zsh_load_file ~/.env-detection
zsh_load_file ~/.aliases
zsh_load_file ~/.modern-aliases
zsh_load_file ~/.dev-automations

# Load platform-specific configurations
zsh_load_file ~/.zshrc.local

# Smart prompt based on environment (cached)
if ! [[ -n "$_ENV_CHECKED" ]]; then
    if is_ssh 2>/dev/null; then
        export PS1="[SSH] $PS1"
    fi

    if is_container 2>/dev/null; then
        export PS1="🐳 $PS1"
    fi
    export _ENV_CHECKED=1
fi

# Performance optimizations
setopt AUTO_CD              # cd by typing directory name if it's not a command
setopt CORRECT              # Correct typos
setopt HIST_REDUCE_BLANKS   # Remove extra blanks from history
setopt INC_APPEND_HISTORY   # Add commands to history as they are typed
setopt SHARE_HISTORY        # Share history between sessions
setopt HIST_IGNORE_DUPS     # Ignore duplicates in history
setopt HIST_IGNORE_SPACE    # Ignore commands that start with space

# Faster completion system
autoload -Uz compinit
if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi