#!/bin/bash

# Cross-platform package installer
# Reads from packages.yaml and installs based on current OS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$DOTFILES_DIR/packages.yaml"

# Check if yq is available for YAML parsing
if ! command -v yq &> /dev/null; then
    echo "Installing yq for YAML parsing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install yq
    elif [[ "$OSTYPE" == "linux"* ]]; then
        sudo apt install -y yq || {
            # Fallback: install yq binary
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo chmod +x /usr/local/bin/yq
        }
    fi
fi

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux"* ]]; then
    OS="ubuntu"
fi

echo "🖥️  Detected OS: $OS"

# Function to install packages for current OS
install_category() {
    local category="$1"
    local install_optional="${2:-false}"

    echo ""
    echo "📦 Installing $category packages..."

    # Get package count
    local package_count
    package_count=$(yq eval ".${category}.packages | length" "$PACKAGES_FILE")

    for ((i=0; i<package_count; i++)); do
        local name package_macos package_ubuntu global_npm optional

        name=$(yq eval ".${category}.packages[$i].name" "$PACKAGES_FILE")
        package_macos=$(yq eval ".${category}.packages[$i].macos" "$PACKAGES_FILE")
        package_ubuntu=$(yq eval ".${category}.packages[$i].ubuntu" "$PACKAGES_FILE")
        global_npm=$(yq eval ".${category}.packages[$i].global_npm" "$PACKAGES_FILE")
        optional=$(yq eval ".${category}.packages[$i].optional" "$PACKAGES_FILE")

        # Skip optional packages unless requested
        if [[ "$optional" == "true" && "$install_optional" != "true" ]]; then
            echo "  ⏭️  Skipping optional package: $name"
            continue
        fi

        echo "  📥 Installing: $name"

        # Install via package manager
        if [[ "$OS" == "macos" && "$package_macos" != "null" ]]; then
            if ! brew list "$package_macos" &>/dev/null; then
                brew install "$package_macos"
            else
                echo "    ✅ Already installed: $package_macos"
            fi
        elif [[ "$OS" == "ubuntu" && "$package_ubuntu" != "null" ]]; then
            if ! dpkg -l | grep -q "^ii  $package_ubuntu "; then
                sudo apt install -y "$package_ubuntu"
            else
                echo "    ✅ Already installed: $package_ubuntu"
            fi
        fi

        # Install global npm package
        if [[ "$global_npm" != "null" && "$global_npm" != "false" ]]; then
            if ! npm list -g "$global_npm" &>/dev/null; then
                npm install -g "$global_npm"
            else
                echo "    ✅ Already installed globally: $global_npm"
            fi
        fi
    done
}

# Main installation
echo "🚀 Cross-platform package installation"

# Parse command line arguments
INSTALL_OPTIONAL=false
CATEGORIES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --optional)
            INSTALL_OPTIONAL=true
            shift
            ;;
        --category)
            CATEGORIES+=("$2")
            shift 2
            ;;
        *)
            CATEGORIES+=("$1")
            shift
            ;;
    esac
done

# If no categories specified, install default ones
if [[ ${#CATEGORIES[@]} -eq 0 ]]; then
    CATEGORIES=("development" "typescript" "modern_cli" "developer_tools" "docker" "productivity")
fi

# Install each category
for category in "${CATEGORIES[@]}"; do
    if yq eval ".${category}" "$PACKAGES_FILE" >/dev/null 2>&1; then
        install_category "$category" "$INSTALL_OPTIONAL"
    else
        echo "❌ Unknown category: $category"
    fi
done

echo ""
echo "✅ Package installation complete!"
echo ""
echo "💡 Usage examples:"
echo "  $0                           # Install default categories"
echo "  $0 --optional              # Install including optional packages"
echo "  $0 --category typescript   # Install only TypeScript tools"
echo "  $0 development modern_cli  # Install specific categories"