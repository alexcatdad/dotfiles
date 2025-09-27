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

# Shell functionality tests
test_shell_functions() {
    log_info "Testing shell functions work..."

    # Source the shell config in a subshell to test
    run_test "zshrc loads without errors" "zsh -c 'source ~/.zshrc' 2>/dev/null"
    run_test "aliases loads without errors" "zsh -c 'source ~/.aliases' 2>/dev/null"

    # Test specific functions exist
    run_test "mkcd function exists" "zsh -c 'source ~/.aliases && typeset -f mkcd' >/dev/null"
    run_test "extract function exists" "zsh -c 'source ~/.aliases && typeset -f extract' >/dev/null"
    run_test "killport function exists" "zsh -c 'source ~/.zshrc && typeset -f killport' >/dev/null"
}

# Git configuration tests
test_git_config() {
    log_info "Testing Git configuration..."

    run_test "git user name set" "git config --global user.name >/dev/null"
    run_test "git user email set" "git config --global user.email >/dev/null"
    run_test "git editor set" "git config --global core.editor >/dev/null"
    run_test "global gitignore configured" "git config --global core.excludesfile >/dev/null"
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

# Cleanup tests (run in container/VM only)
test_cleanup() {
    if [[ -n "${CI}" || -n "${CONTAINER}" ]]; then
        log_info "Testing cleanup procedures..."
        run_test "backup script exists" "[ -f $DOTFILES_DIR/scripts/backup-configs.sh ]"
        run_test "sync script exists" "[ -f $DOTFILES_DIR/scripts/sync-settings.sh ]"
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
    test_tools
    test_shell_functions
    test_git_config
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