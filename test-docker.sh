#!/bin/bash

# Docker testing script for dotfiles
# Provides easy commands to test different scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🐳 Dotfiles Docker Testing Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  fresh       Test fresh installation (bootstrap.sh)"
    echo "  safe        Test safe installation (install-safe.sh)"
    echo "  dev         Start interactive development container"
    echo "  macos       Test macOS-like installation"
    echo "  build       Build the Docker image"
    echo "  clean       Clean up all containers and images"
    echo "  logs        Show logs from last test run"
    echo "  shell       Get shell access to running container"
    echo ""
    echo "Examples:"
    echo "  $0 fresh           # Test bootstrap installation"
    echo "  $0 safe            # Test safe installation"
    echo "  $0 dev             # Start development container"
    echo "  $0 shell fresh     # Get shell in fresh test container"
}

build_image() {
    echo -e "${BLUE}🔨 Building Docker image...${NC}"
    docker-compose build
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
}

test_fresh() {
    echo -e "${BLUE}🚀 Testing fresh installation...${NC}"
    docker-compose down dotfiles-fresh 2>/dev/null || true
    docker-compose up --build dotfiles-fresh
}

test_safe() {
    echo -e "${BLUE}🛡️ Testing safe installation...${NC}"
    docker-compose down dotfiles-safe 2>/dev/null || true
    docker-compose up --build dotfiles-safe
}

test_macos() {
    echo -e "${BLUE}🍎 Testing macOS-like installation...${NC}"
    docker-compose down dotfiles-macos-sim 2>/dev/null || true
    docker-compose up --build dotfiles-macos-sim
}

start_dev() {
    echo -e "${BLUE}💻 Starting development container...${NC}"
    echo -e "${YELLOW}Use this for manual testing and development${NC}"
    docker-compose down dotfiles-dev 2>/dev/null || true
    docker-compose up --build dotfiles-dev
}

get_shell() {
    local container_name="$1"
    case "$container_name" in
        fresh)
            container_name="dotfiles-test-fresh"
            ;;
        safe)
            container_name="dotfiles-test-safe"
            ;;
        dev)
            container_name="dotfiles-dev"
            ;;
        macos)
            container_name="dotfiles-macos-sim"
            ;;
        *)
            echo -e "${RED}❌ Unknown container: $container_name${NC}"
            echo "Available containers: fresh, safe, dev, macos"
            exit 1
            ;;
    esac

    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        echo -e "${BLUE}🐚 Connecting to $container_name...${NC}"
        docker exec -it "$container_name" /bin/zsh
    else
        echo -e "${RED}❌ Container $container_name is not running${NC}"
        echo "Start it first with: $0 ${1}"
        exit 1
    fi
}

clean_up() {
    echo -e "${BLUE}🧹 Cleaning up Docker containers and images...${NC}"

    # Stop and remove containers
    docker-compose down --remove-orphans 2>/dev/null || true

    # Remove dangling images
    docker image prune -f

    # Remove dotfiles-related containers
    docker ps -a --format "table {{.Names}}" | grep "dotfiles" | xargs -r docker rm -f

    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

show_logs() {
    echo -e "${BLUE}📋 Recent Docker logs...${NC}"
    docker-compose logs --tail=50
}

run_comprehensive_test() {
    echo -e "${BLUE}🧪 Running comprehensive test suite...${NC}"

    # Build image first
    build_image

    echo -e "${YELLOW}Testing fresh installation...${NC}"
    if test_fresh; then
        echo -e "${GREEN}✅ Fresh installation test passed${NC}"
    else
        echo -e "${RED}❌ Fresh installation test failed${NC}"
        return 1
    fi

    echo -e "${YELLOW}Testing safe installation...${NC}"
    if test_safe; then
        echo -e "${GREEN}✅ Safe installation test passed${NC}"
    else
        echo -e "${RED}❌ Safe installation test failed${NC}"
        return 1
    fi

    echo -e "${GREEN}🎉 All tests passed!${NC}"
}

# Main script logic
case "${1:-help}" in
    fresh)
        test_fresh
        ;;
    safe)
        test_safe
        ;;
    dev)
        start_dev
        ;;
    macos)
        test_macos
        ;;
    build)
        build_image
        ;;
    clean)
        clean_up
        ;;
    logs)
        show_logs
        ;;
    shell)
        get_shell "$2"
        ;;
    test-all)
        run_comprehensive_test
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
