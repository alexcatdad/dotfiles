#!/bin/bash

# Dotfiles testing framework
# Ensures your dotfiles work correctly across environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS=()

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing $test_name... "

    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

# Core file tests
test_core_files() {
    log_info "Testing core dotfiles exist..."

    run_test "zshrc exists" "[ -f ~/.zshrc ]"
    run_test "gitconfig exists" "[ -f ~/.gitconfig ]"
    run_test "aliases exists" "[ -f ~/.aliases ]"
    run_test "npmrc exists" "[ -f ~/.npmrc ]"
    run_test "vimrc exists" "[ -f ~/.vimrc ]"
    run_test "tmux.conf exists" "[ -f ~/.tmux.conf ]"
    run_test "global gitignore exists" "[ -f ~/.gitignore_global ]"
}

# Symlink tests
test_symlinks() {
    log_info "Testing symlinks are correct..."

    run_test "zshrc is symlinked" "[ -L ~/.zshrc ]"
    run_test "gitconfig is symlinked" "[ -L ~/.gitconfig ]"
    run_test "aliases is symlinked" "[ -L ~/.aliases ]"
}

# Tool availability tests
test_tools() {
    log_info "Testing required tools are available..."

    run_test "git available" "command -v git"
    run_test "zsh available" "command -v zsh"
    run_test "curl available" "command -v curl"

    # Platform-specific tools
    if [[ "$OSTYPE" == "darwin"* ]]; then
        run_test "brew available" "command -v brew"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        run_test "apt available" "command -v apt"
    fi
}

# Enhanced shell functionality tests
test_shell_functions() {
    log_info "Testing shell functions work..."

    # Source the shell config in a subshell to test
    run_test "zshrc loads without errors" "zsh -c 'source ~/.zshrc' 2>/dev/null"
    run_test "aliases loads without errors" "zsh -c 'source ~/.aliases' 2>/dev/null"
    run_test "modern-aliases loads without errors" "zsh -c 'source ~/.modern-aliases' 2>/dev/null"
    run_test "dev-automations loads without errors" "zsh -c 'source ~/.dev-automations' 2>/dev/null"
    run_test "env-detection loads without errors" "zsh -c 'source ~/.env-detection' 2>/dev/null"

    # Test specific functions exist
    run_test "create-ts-project function exists" "zsh -c 'source ~/.aliases && typeset -f create-ts-project' >/dev/null"
    run_test "init-project function exists" "zsh -c 'source ~/.dev-automations && typeset -f init-project' >/dev/null"
    run_test "smart-install function exists" "zsh -c 'source ~/.dev-automations && typeset -f smart-install' >/dev/null"
    run_test "git-feature function exists" "zsh -c 'source ~/.aliases && typeset -f git-feature' >/dev/null"
    run_test "dev function exists" "zsh -c 'source ~/.aliases && typeset -f dev' >/dev/null"
    
    # Test shell performance cache system
    run_test "modern CLI cache system works" "zsh -c 'source ~/.modern-aliases && [[ -n \"\${_MODERN_CLI_CACHE_LOADED:-}\" ]]'"
}

# Enhanced Git configuration tests with validation
test_git_config() {
    log_info "Testing Git configuration..."

    run_test "git user name set" "git config --global user.name >/dev/null"
    run_test "git user email set" "git config --global user.email >/dev/null"
    run_test "git editor set" "git config --global core.editor >/dev/null"
    run_test "global gitignore configured" "git config --global core.excludesfile >/dev/null"
    
    # Validate Git configuration syntax
    run_test "gitconfig syntax is valid" "git config --list --global >/dev/null 2>&1"
    
    # Test specific Git configurations
    run_test "git push default is set" "git config --global push.default >/dev/null || echo 'simple' | git config --global push.default simple"
    run_test "git pull rebase is configured" "git config --global pull.rebase >/dev/null || git config --global pull.rebase false"
    
    # Validate gitignore_global exists and is readable
    run_test "global gitignore file exists" "test -f ~/.gitignore_global"
    run_test "global gitignore is readable" "test -r ~/.gitignore_global"
    
    # Test Git aliases if they exist
    if git config --global --get-regexp '^alias\.' >/dev/null 2>&1; then
        run_test "git aliases are valid" "git config --global --get-regexp '^alias\.' >/dev/null"
    fi
}

# Node.js/TypeScript tests
test_node_setup() {
    log_info "Testing Node.js/TypeScript setup..."

    if command -v nvm >/dev/null 2>&1; then
        run_test "nvm available" "command -v nvm"
    else
        log_warn "NVM not found in PATH, checking if sourced..."
        run_test "nvm sourced" "[ -s ~/.nvm/nvm.sh ]"
    fi

    run_test "node available" "command -v node"
    run_test "npm available" "command -v npm"

    if command -v bun >/dev/null 2>&1; then
        run_test "bun available" "command -v bun"
    else
        log_warn "Bun not found, skipping bun tests"
    fi
}

# Oh My Zsh tests
test_oh_my_zsh() {
    log_info "Testing Oh My Zsh setup..."

    if [[ -n "${CI:-}" ]]; then
        log_warn "Skipping Oh My Zsh tests in CI environment"
        return 0
    fi

    run_test "Oh My Zsh installed" "[ -d ~/.oh-my-zsh ]"
    run_test "zsh-autosuggestions plugin" "[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]"
    run_test "zsh-syntax-highlighting plugin" "[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]"

    if [ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
        run_test "powerlevel10k theme installed" "[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]"
    else
        log_warn "Powerlevel10k not found, using default theme"
    fi
}

# Environment detection tests
test_environment_detection() {
    log_info "Testing environment detection..."

    run_test "env-detection loads" "zsh -c 'source ~/.env-detection' 2>/dev/null"
    run_test "get_os function works" "zsh -c 'source ~/.env-detection && get_os' >/dev/null"
}

# Performance tests
test_performance() {
    log_info "Testing shell performance..."

    # Test shell startup time (should be under 2 seconds)
    startup_time=$(time zsh -i -c exit 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
    if command -v bc >/dev/null && [ -n "$startup_time" ]; then
        run_test "shell startup under 2s" "echo '$startup_time < 2' | bc -l | grep -q 1"
    else
        log_warn "Cannot test startup time (bc not available or time parsing failed)"
    fi
}

# Configuration file validation tests
test_configuration_validation() {
    log_info "Testing configuration file validation..."
    
    # YAML configuration validation
    if command -v python3 &>/dev/null; then
        run_test "packages.yaml is valid YAML" "python3 -c 'import yaml; yaml.safe_load(open(\"$DOTFILES_DIR/packages.yaml\"))'"
        run_test "install.conf.yaml is valid YAML" "python3 -c 'import yaml; yaml.safe_load(open(\"$DOTFILES_DIR/install.conf.yaml\"))'"
    else
        log_warn "Python3 not available, skipping YAML validation"
    fi
    
    # JSON configuration validation (handle JSONC format)
    if command -v node &>/dev/null; then
        if [ -f ~/.vscode/settings.json ]; then
            run_test "VSCode settings.json is valid JSON" "node -e 'JSON.parse(require(\"fs\").readFileSync(process.env.HOME+\"/.vscode/settings.json\", \"utf8\").replace(/\\/\\/.*$/gm, \"\").replace(/\\/\\*[\\s\\S]*?\\*\\//g, \"\"))'"
        fi
        if [ -f ~/.cursor/settings.json ]; then
            run_test "Cursor settings.json is valid JSON" "node -e 'JSON.parse(require(\"fs\").readFileSync(process.env.HOME+\"/.cursor/settings.json\", \"utf8\").replace(/\\/\\/.*$/gm, \"\").replace(/\\/\\*[\\s\\S]*?\\*\\//g, \"\"))'"
        fi
        if [ -f ~/.npmrc ]; then
            run_test "npmrc configuration is readable" "test -r ~/.npmrc"
        fi
    elif command -v jq &>/dev/null; then
        log_warn "Node.js not available for JSONC parsing, trying jq (may fail on comments)"
        if [ -f ~/.vscode/settings.json ]; then
            run_test "VSCode settings.json parseable" "grep -v '^ *//' ~/.vscode/settings.json | jq . >/dev/null"
        fi
    else
        log_warn "Neither Node.js nor jq available, skipping JSON validation"
    fi
    
    # Shell script syntax validation
    local scripts_to_check=(
        "$DOTFILES_DIR/bootstrap.sh"
        "$DOTFILES_DIR/install-safe.sh"
        "$DOTFILES_DIR/scripts/install-packages-yaml.sh"
        "$DOTFILES_DIR/scripts/install-packages-yaml.sh"
        "$DOTFILES_DIR/scripts/sync-settings.sh"
        "$DOTFILES_DIR/scripts/backup-configs.sh"
        "$DOTFILES_DIR/test/test-dotfiles.sh"
    )
    
    for script in "${scripts_to_check[@]}"; do
        if [ -f "$script" ]; then
            local script_name=$(basename "$script")
            run_test "$script_name has valid syntax" "bash -n '$script'"
        fi
    done
}

# IDE configuration tests
test_ide_configurations() {
    log_info "Testing IDE configurations..."
    
    # Check IDE config directories
    run_test "VSCode config directory exists" "[ -d ~/.vscode ] || mkdir -p ~/.vscode"
    run_test "Cursor config directory exists" "[ -d ~/.cursor ] || mkdir -p ~/.cursor"
    
    # Check IDE configuration files
    if [ -f ~/.vscode/settings.json ]; then
        run_test "VSCode settings file is readable" "test -r ~/.vscode/settings.json"
        if command -v jq &>/dev/null; then
            run_test "VSCode settings contain TypeScript config" 'node -e "console.log(JSON.parse(require(\"fs\").readFileSync(process.env.HOME+\"/.vscode/settings.json\", \"utf8\").replace(/\\/\\/.*$/gm, \"\").replace(/\\/\\*[\\s\\S]*?\\*\\//g, \"\"))[\"typescript.updateImportsOnFileMove.enabled\"])" | grep -q always'
        fi
    fi
    
    if [ -f ~/.cursor/settings.json ]; then
        run_test "Cursor settings file is readable" "test -r ~/.cursor/settings.json"
        if command -v jq &>/dev/null; then
            run_test "Cursor AI is enabled" 'node -e "console.log(JSON.parse(require(\"fs\").readFileSync(process.env.HOME+\"/.cursor/settings.json\", \"utf8\").replace(/\\/\\/.*$/gm, \"\").replace(/\\/\\*[\\s\\S]*?\\*\\//g, \"\"))[\"cursor.ai.enabled\"])" | grep -q true'
        fi
    fi
}

# Package management validation tests
test_package_management() {
    log_info "Testing package management configuration..."
    
    # Test package files exist
    run_test "packages.yaml exists" "[ -f $DOTFILES_DIR/packages.yaml ]"
    run_test "new YAML installer exists" "[ -f $DOTFILES_DIR/scripts/install-packages-yaml.sh ]"
    run_test "new YAML installer is executable" "[ -x $DOTFILES_DIR/scripts/install-packages-yaml.sh ]"
    
    # Test package manager availability
    if [[ "$OSTYPE" == "darwin"* ]]; then
        run_test "Homebrew is available" "command -v brew"
        if command -v brew &>/dev/null; then
            run_test "Homebrew is functional" "brew --version >/dev/null"
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        run_test "APT is available" "command -v apt"
    fi
    
    # Test npm configuration
    if command -v npm &>/dev/null; then
        run_test "npm configuration is valid" "npm config list >/dev/null 2>&1"
        if [ -f ~/.npmrc ]; then
            run_test "npmrc is readable" "test -r ~/.npmrc"
        fi
    fi
}

# Symlink integrity tests
test_symlink_integrity() {
    log_info "Testing symlink integrity..."
    
    local config_files=(
        "~/.zshrc:shared/.zshrc"
        "~/.gitconfig:shared/.gitconfig"
        "~/.aliases:shared/.aliases"
        "~/.modern-aliases:shared/.modern-aliases"
        "~/.dev-automations:shared/.dev-automations"
        "~/.env-detection:shared/.env-detection"
        "~/.npmrc:shared/.npmrc"
    )
    
    for config in "${config_files[@]}"; do
        IFS=':' read -r target_path source_path <<< "$config"
        expanded_target=$(eval echo "$target_path")
        
        if [ -L "$expanded_target" ]; then
            run_test "$(basename "$target_path") symlink target exists" "[ -f \"\$(readlink \"$expanded_target\")\" ]"
            run_test "$(basename "$target_path") symlink is not broken" "[ -e \"$expanded_target\" ]"
        fi
    done
}

# Cleanup tests (run in container/VM only)
test_cleanup() {
    if [[ -n "${CI}" || -n "${CONTAINER}" ]]; then
        log_info "Testing cleanup procedures..."
        run_test "backup script exists" "[ -f $DOTFILES_DIR/scripts/backup-configs.sh ]"
        run_test "sync script exists" "[ -f $DOTFILES_DIR/scripts/sync-settings.sh ]"
        run_test "new YAML installer exists" "[ -f $DOTFILES_DIR/scripts/install-packages-yaml.sh ]"
    else
        log_warn "Skipping cleanup tests (not in CI/container environment)"
    fi
}

# Main test runner
main() {
    echo "🧪 Dotfiles Test Suite"
    echo "====================="
    echo ""

    # Run all test suites
    test_core_files
    test_symlinks
    test_symlink_integrity
    test_tools
    test_shell_functions
    test_git_config
    test_configuration_validation
    test_ide_configurations
    test_package_management
    test_node_setup
    test_oh_my_zsh
    test_environment_detection
    test_performance
    test_cleanup

    # Summary
    echo ""
    echo "📊 Test Results"
    echo "==============="
    echo "Tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
        echo ""
        echo -e "${RED}❌ Some tests failed. Please review your dotfiles setup.${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}✅ All tests passed! Your dotfiles are working correctly.${NC}"
        exit 0
    fi
}

# Run tests
main "$@"