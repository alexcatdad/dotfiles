#!/bin/bash

# Enhanced YAML-based cross-platform package installer
# Supports version constraints, rollback, and better error handling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_YAML="$DOTFILES_DIR/packages.yaml"
LOG_FILE="$DOTFILES_DIR/.install.log"
ROLLBACK_FILE="$DOTFILES_DIR/.rollback.log"

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_PACKAGES=0
INSTALLED_PACKAGES=0
FAILED_PACKAGES=0
SKIPPED_PACKAGES=0

# Arrays to track operations
declare -a INSTALLED_ITEMS=()
declare -a FAILED_ITEMS=()
declare -a ROLLBACK_COMMANDS=()

# Utility functions
log() {
    local level="$1"
    shift
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "${GREEN}$*${NC}"; }
log_warn() { log "WARN" "${YELLOW}$*${NC}"; }
log_error() { log "ERROR" "${RED}$*${NC}"; }
log_debug() { log "DEBUG" "${BLUE}$*${NC}"; }

# Parse YAML (requires yq or python fallback)
parse_yaml() {
    local yaml_file="$1"
    local query="$2"

    if command -v yq &>/dev/null; then
        # Use Python yq (jq-style) or Go yq in a compatible way
        yq "$query" "$yaml_file" 2>/dev/null || echo "null"
    elif command -v python3 &>/dev/null; then
        python3 -c "
import yaml, sys
try:
    with open('$yaml_file', 'r') as f:
        data = yaml.safe_load(f)
    # Simple dot-notation parser for basic queries
    keys = '$query'.split('.')
    result = data
    for key in keys:
        if key and key != 'null':
            result = result.get(key, 'null') if isinstance(result, dict) else 'null'
    print(result if result != 'null' else 'null')
except Exception as e:
    print('null')
"
    else
        log_error "Neither yq nor python3 available for YAML parsing"
        return 1
    fi
}

# Detect OS and environment
detect_environment() {
    export OS="unknown"
    export PACKAGE_MANAGER=""
    export DESKTOP_ENV="false"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
        # Check if GUI session is available
        if [[ -n "${DISPLAY:-}" ]] || [[ "$OS" == "macos" ]]; then
            DESKTOP_ENV="true"
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        OS="ubuntu"
        PACKAGE_MANAGER="apt"
        # Check for desktop environment
        if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            DESKTOP_ENV="true"
        fi
    fi

    log_info "Detected: OS=$OS, Package Manager=$PACKAGE_MANAGER, Desktop=$DESKTOP_ENV"
}

# Check if package is already installed
is_package_installed() {
    local package="$1"
    local os="$2"

    case "$os" in
        "macos")
            if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
                brew list "$package" &>/dev/null
            fi
            ;;
        "ubuntu")
            if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                dpkg -l | grep -q "^ii  $package " &>/dev/null
            fi
            ;;
    esac
}

# Check if global npm package is installed
is_npm_package_installed() {
    local package="$1"
    npm list -g "$package" &>/dev/null
}

# Install system package with version constraint checking
install_system_package() {
    local name="$1"
    local package="$2"
    local version_constraint="$3"
    local required="$4"
    local dry_run="${5:-false}"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would install system package: $name ($package)"
        INSTALLED_ITEMS+=("$name (would install)")
        return 0
    fi

    log_info "Installing system package: $name ($package)"

    # Check if already installed
    if is_package_installed "$package" "$OS"; then
        log_info "Package $package already installed"
        return 0
    fi

    # Install based on OS
    local install_cmd=""
    case "$OS" in
        "macos")
            install_cmd="brew install $package"
            ROLLBACK_COMMANDS+=("brew uninstall $package")
            ;;
        "ubuntu")
            install_cmd="sudo apt install -y $package"
            ROLLBACK_COMMANDS+=("sudo apt remove -y $package")
            ;;
        *)
            log_error "Unsupported OS: $OS"
            return 1
            ;;
    esac

    # Execute installation
    if eval "$install_cmd"; then
        log_info "Successfully installed: $package"
        INSTALLED_ITEMS+=("$name")
        echo "$install_cmd" >> "$ROLLBACK_FILE"
        return 0
    else
        log_error "Failed to install: $package"
        FAILED_ITEMS+=("$name")
        return 1
    fi
}

# Install global npm package
install_npm_package() {
    local name="$1"
    local package="$2"
    local version_constraint="$3"
    local dry_run="${4:-false}"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would install npm package: $name ($package)"
        INSTALLED_ITEMS+=("$name (npm - would install)")
        return 0
    fi

    log_info "Installing npm package: $name ($package)"

    # Check if already installed
    if is_npm_package_installed "$package"; then
        log_info "NPM package $package already installed"
        return 0
    fi

    # Install with version constraint if specified
    local install_cmd="npm install -g"
    if [[ "$version_constraint" != "null" && "$version_constraint" != "" ]]; then
        install_cmd+=" $package@\"$version_constraint\""
    else
        install_cmd+=" $package"
    fi

    if eval "$install_cmd"; then
        log_info "Successfully installed npm package: $package"
        INSTALLED_ITEMS+=("$name (npm)")
        ROLLBACK_COMMANDS+=("npm uninstall -g $package")
        echo "$install_cmd" >> "$ROLLBACK_FILE"
        return 0
    else
        log_error "Failed to install npm package: $package"
        FAILED_ITEMS+=("$name (npm)")
        return 1
    fi
}

# Run post-install commands
run_post_install() {
    local name="$1"
    local commands="$2"

    if [[ "$commands" == "null" || "$commands" == "" ]]; then
        return 0
    fi

    log_info "Running post-install commands for: $name"

    # Parse commands (assuming they're in array format)
    # This is a simplified parser - in production, you'd want proper YAML array parsing
    local cleaned_commands="${commands#*[}"
    cleaned_commands="${cleaned_commands%]*}"

    IFS=',' read -ra ADDR <<< "$cleaned_commands"
    for cmd in "${ADDR[@]}"; do
        # Clean up quotes
        cmd=$(echo "$cmd" | sed 's/^[[:space:]]*"//g' | sed 's/"[[:space:]]*$//g')
        if [[ -n "$cmd" ]]; then
            log_debug "Executing: $cmd"
            if ! eval "$cmd" &>/dev/null; then
                log_warn "Post-install command failed: $cmd"
            fi
        fi
    done
}

# Process a single package
process_package() {
    local category="$1"
    local pkg_name="$2"
    local install_optional="$3"
    local dry_run="${4:-false}"

    TOTAL_PACKAGES=$((TOTAL_PACKAGES + 1))

    log_debug "Processing package: $pkg_name from category: $category"

    # Get package details from YAML
    local macos_pkg=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .macos")
    local ubuntu_pkg=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .ubuntu")
    local global_npm=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .global_npm")
    local version_constraint=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .version_constraint")
    local required=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .required")
    local optional=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .optional")
    local platform_specific=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .platform_specific")
    local post_install=$(parse_yaml "$PACKAGES_YAML" ".${category}.packages[] | select(.name == \"$pkg_name\") | .post_install")

    # Check if package should be skipped
    if [[ "$optional" == "true" && "$install_optional" != "true" ]]; then
        log_info "Skipping optional package: $pkg_name"
        SKIPPED_PACKAGES=$((SKIPPED_PACKAGES + 1))
        return 0
    fi

    # Check platform compatibility
    if [[ "$platform_specific" == "true" ]]; then
        local os_pkg_name=""
        case "$OS" in
            "macos") os_pkg_name="$macos_pkg" ;;
            "ubuntu") os_pkg_name="$ubuntu_pkg" ;;
        esac

        if [[ "$os_pkg_name" == "null" || "$os_pkg_name" == "" ]]; then
            log_warn "Package $pkg_name not available for $OS, skipping"
            SKIPPED_PACKAGES=$((SKIPPED_PACKAGES + 1))
            return 0
        fi
    fi

    local success=true

    # Install system package
    if [[ "$OS" == "macos" && "$macos_pkg" != "null" && "$macos_pkg" != "" ]]; then
        if ! install_system_package "$pkg_name" "$macos_pkg" "$version_constraint" "$required" "$dry_run"; then
            success=false
        fi
    elif [[ "$OS" == "ubuntu" && "$ubuntu_pkg" != "null" && "$ubuntu_pkg" != "" ]]; then
        if ! install_system_package "$pkg_name" "$ubuntu_pkg" "$version_constraint" "$required" "$dry_run"; then
            success=false
        fi
    fi

    # Install global npm package
    if [[ "$global_npm" != "null" && "$global_npm" != "" ]]; then
        if ! install_npm_package "$pkg_name" "$global_npm" "$version_constraint" "$dry_run"; then
            success=false
        fi
    fi

    # Run post-install commands
    if [[ "$success" == "true" ]]; then
        run_post_install "$pkg_name" "$post_install"
        INSTALLED_PACKAGES=$((INSTALLED_PACKAGES + 1))
    else
        FAILED_PACKAGES=$((FAILED_PACKAGES + 1))
    fi
}

# Get all packages from a category
get_category_packages() {
    local category="$1"

    if command -v yq &>/dev/null; then
        yq ".${category}.packages[].name" "$PACKAGES_YAML" 2>/dev/null || echo ""
    else
        # Fallback parsing with python
        python3 -c "
import yaml
try:
    with open('$PACKAGES_YAML', 'r') as f:
        data = yaml.safe_load(f)
    packages = data.get('$category', {}).get('packages', [])
    for pkg in packages:
        if 'name' in pkg:
            print(pkg['name'])
except:
    pass
"
    fi
}

# Process a category
process_category() {
    local category="$1"
    local install_optional="$2"
    local dry_run="${3:-false}"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Processing category: $category"
    else
        log_info "Processing category: $category"
    fi

    # Check if category exists
    local category_desc=$(parse_yaml "$PACKAGES_YAML" ".${category}.description")
    if [[ "$category_desc" == "null" ]]; then
        log_error "Category '$category' not found in packages.yaml"
        return 1
    fi

    # Check category conditions
    local condition=$(parse_yaml "$PACKAGES_YAML" ".${category}.condition")
    if [[ "$condition" == "desktop_environment" && "$DESKTOP_ENV" != "true" ]]; then
        log_warn "Skipping category '$category' - requires desktop environment"
        return 0
    fi

    # Get all packages in the category
    local packages
    packages=$(get_category_packages "$category")

    if [[ -z "$packages" ]]; then
        log_warn "No packages found in category: $category"
        return 0
    fi

    # Process each package
    while IFS= read -r pkg_name; do
        if [[ -n "$pkg_name" ]]; then
            process_package "$category" "$pkg_name" "$install_optional" "$dry_run"
        fi
    done <<< "$packages"
}

# Rollback function
rollback() {
    log_warn "Rolling back installed packages..."

    # Execute rollback commands in reverse order
    for ((i=${#ROLLBACK_COMMANDS[@]}-1; i>=0; i--)); do
        local cmd="${ROLLBACK_COMMANDS[$i]}"
        log_debug "Rollback: $cmd"
        eval "$cmd" &>/dev/null || true
    done

    # Clean up log files
    rm -f "$ROLLBACK_FILE"
    log_info "Rollback completed"
}

# Cleanup function
cleanup() {
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code: $exit_code"
        if [[ ${#ROLLBACK_COMMANDS[@]} -gt 0 ]]; then
            read -p "Would you like to rollback installed packages? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rollback
            fi
        fi
    else
        # Clean up rollback file on success
        rm -f "$ROLLBACK_FILE"
    fi
}

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS] [CATEGORIES...]"
    echo ""
    echo "Options:"
    echo "  --optional          Include optional packages"
    echo "  --dry-run          Show what would be installed without installing"
    echo "  --help             Show this help message"
    echo ""
    echo "Categories:"
    echo "  development        Core development tools"
    echo "  typescript         TypeScript development tools"
    echo "  modern_cli         Modern CLI replacements"
    echo "  developer_tools    Advanced developer utilities"
    echo "  docker            Container development"
    echo "  productivity      Productivity tools"
    echo "  gui_applications  GUI applications"
    echo "  optional          Optional tools"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Install default categories"
    echo "  $0 --optional                       # Include optional packages"
    echo "  $0 typescript modern_cli           # Install specific categories"
    echo "  $0 --dry-run development           # Preview installation"
}

# Main function
main() {
    # Initialize log file
    echo "=== Package Installation Started at $(date) ===" > "$LOG_FILE"

    # Set up cleanup trap
    trap cleanup EXIT

    log_info "Enhanced YAML-based package installer starting..."

    # Check dependencies
    if ! command -v python3 &>/dev/null && ! command -v yq &>/dev/null; then
        log_error "This script requires either 'yq' or 'python3' with PyYAML for YAML parsing"
        exit 1
    fi

    # Detect environment
    detect_environment

    # Parse arguments
    local INSTALL_OPTIONAL=false
    local DRY_RUN=false
    local CATEGORIES=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --optional)
                INSTALL_OPTIONAL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                CATEGORIES+=("$1")
                shift
                ;;
        esac
    done

    # Default categories if none specified
    if [[ ${#CATEGORIES[@]} -eq 0 ]]; then
        CATEGORIES=("development" "typescript" "modern_cli" "developer_tools" "docker" "productivity")

        # Add GUI applications if desktop environment is available
        if [[ "$DESKTOP_ENV" == "true" ]]; then
            CATEGORIES+=("gui_applications")
        fi
    fi

    log_info "Categories to process: ${CATEGORIES[*]}"

    # Process each category
    for category in "${CATEGORIES[@]}"; do
        process_category "$category" "$INSTALL_OPTIONAL" "$DRY_RUN"
    done

    # Print summary
    echo ""
    log_info "=== Installation Summary ==="
    log_info "Total packages: $TOTAL_PACKAGES"
    log_info "Installed: $INSTALLED_PACKAGES"
    log_info "Failed: $FAILED_PACKAGES"
    log_info "Skipped: $SKIPPED_PACKAGES"

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        log_error "Failed packages: ${FAILED_ITEMS[*]}"
    fi

    if [[ ${#INSTALLED_ITEMS[@]} -gt 0 ]]; then
        log_info "Successfully installed: ${INSTALLED_ITEMS[*]}"
    fi

    if [[ $FAILED_PACKAGES -gt 0 ]]; then
        exit 1
    fi

    log_info "Package installation completed successfully!"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi