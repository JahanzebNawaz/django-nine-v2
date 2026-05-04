#!/bin/bash

##############################################################################
# Test Environment Manager for django-nine-v2
# Creates and manages virtual environments for multiple Python versions
# Runs tests in each environment
#
# Usage:
#   ./scripts/test_envs.sh                    # Show help
#   ./scripts/test_envs.sh create             # Create all venvs
#   ./scripts/test_envs.sh create 311         # Create specific venv (py311)
#   ./scripts/test_envs.sh test               # Run tests in all venvs
#   ./scripts/test_envs.sh test 311           # Run tests in specific venv
#   ./scripts/test_envs.sh clean              # Remove all venvs
#   ./scripts/test_envs.sh list               # List available Python versions
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
VENV_BASE_DIR="$PROJECT_ROOT/.venv"
PYTHON_VERSIONS=("310" "311" "312" "313" "314")

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_section() {
    echo -e "${MAGENTA}>>> $1${NC}"
}

show_help() {
    cat << EOF
Usage: ./scripts/test_envs.sh [COMMAND] [VERSION]

Commands:
    create              Create all virtual environments
    create [VERSION]    Create specific venv (e.g., create 311)
    test                Run tests in all virtual environments
    test [VERSION]      Run tests in specific venv (e.g., test 311)
    clean               Remove all virtual environments
    list                List available Python versions on system
    help                Show this help message

Examples:
    ./scripts/test_envs.sh create              # Create .venv/310 through .venv/314
    ./scripts/test_envs.sh create 312          # Create only .venv/312
    ./scripts/test_envs.sh test 311            # Run tests in .venv/311
    ./scripts/test_envs.sh test                # Run tests in all venvs
    ./scripts/test_envs.sh clean               # Delete all venvs
    ./scripts/test_envs.sh list                # Show available Python versions

EOF
}

# Find Python executable for a version
find_python_version() {
    local version=$1
    local major=${version:0:1}
    local minor=${version:1:2}
    
    # Try different naming conventions
    for cmd in "python${major}.${minor}" "python3.${minor}" "python${version}"; do
        if command -v "$cmd" &> /dev/null; then
            echo "$cmd"
            return 0
        fi
    done
    
    return 1
}

# List available Python versions
list_python_versions() {
    print_header "Available Python Versions"
    
    if ! command -v uv &> /dev/null; then
        print_error "uv is not installed. Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
    
    echo ""
    print_info "Testing Python availability via uv..."
    echo ""
    
    local found=0
    for version in "${PYTHON_VERSIONS[@]}"; do
        local major=${version:0:1}
        local minor=${version:1:2}
        
        # Try to get Python version info via uv
        if py_version=$(uv python list --all-versions 2>/dev/null | grep "$major\.$minor" | head -1); then
            print_success "$version -> $py_version"
            found=$((found + 1))
        else
            # Fallback: try to find Python directly
            if python_cmd=$(find_python_version "$version"); then
                local py_info=$("$python_cmd" --version 2>&1)
                print_success "$version -> $py_info (local)"
                found=$((found + 1))
            else
                print_warning "$version -> NOT FOUND (uv will attempt to download)"
            fi
        fi
    done
    
    echo ""
    print_info "Found $found/$((${#PYTHON_VERSIONS[@]})) Python versions configured"
    echo ""
    print_info "Note: uv can automatically download Python versions if not available locally"
}

# Create virtual environment
create_venv() {
    local version=$1
    local venv_path="$VENV_BASE_DIR/$version"
    local major=${version:0:1}
    local minor=${version:1:2}
    
    print_section "Creating .venv/$version"
    
    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        print_error "uv is not installed. Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
    
    # Check if venv already exists
    if [ -d "$venv_path" ]; then
        print_warning "Virtual environment already exists: $venv_path"
        read -p "Recreate? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Skipped"
            return 0
        fi
        print_info "Removing existing environment..."
        rm -rf "$venv_path"
    fi
    
    # Create venv using uv
    print_info "Creating venv with Python $major.$minor using uv..."
    if uv venv "$venv_path" --python "$major.$minor" > /dev/null 2>&1; then
        print_success "Created $venv_path"
        
        # Install project and dependencies
        print_info "Installing project, dependencies, and test requirements..."
        if uv pip install --python "$venv_path" -e "$PROJECT_ROOT" pytest pytest-cov beautifulsoup4 tox build twine > /dev/null 2>&1; then
            print_success ".venv/$version ready"
            return 0
        else
            print_error "Failed to install project dependencies"
            return 1
        fi
    else
        print_error "Failed to create virtual environment with uv"
        print_warning "Make sure Python $major.$minor is available on your system"
        return 1
    fi
}

# Create all venvs
create_all_venvs() {
    print_header "Creating Virtual Environments"
    echo ""
    
    local success=0
    local failed=0
    
    for version in "${PYTHON_VERSIONS[@]}"; do
        if create_venv "$version"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
    done
    
    print_header "Summary"
    print_success "$success environments created"
    if [ $failed -gt 0 ]; then
        print_error "$failed environments failed"
        return 1
    fi
}

# Run tests in venv
run_tests_in_venv() {
    local version=$1
    local venv_path="$VENV_BASE_DIR/$version"
    
    if [ ! -d "$venv_path" ]; then
        print_error "Virtual environment not found: .venv/$version"
        print_info "Run: ./scripts/test_envs.sh create $version"
        return 1
    fi
    
    print_section "Testing with Python $version (.venv/$version)"
    
    # Show Python version
    print_info "Python: $("$venv_path/bin/python" --version)"
    
    # Run tests
    cd "$PROJECT_ROOT"
    if "$venv_path/bin/python" runtests.py; then
        print_success "Tests passed in .venv/$version"
        return 0
    else
        print_error "Tests failed in .venv/$version"
        return 1
    fi
}

# Run tests in all venvs
run_all_tests() {
    print_header "Running Tests in All Environments"
    echo ""
    
    local results=()
    local success=0
    local failed=0
    
    for version in "${PYTHON_VERSIONS[@]}"; do
        if [ -d "$VENV_BASE_DIR/$version" ]; then
            if run_tests_in_venv "$version"; then
                results+=("${GREEN}✓ .venv/$version${NC}")
                success=$((success + 1))
            else
                results+=("${RED}✗ .venv/$version${NC}")
                failed=$((failed + 1))
            fi
        else
            results+=("${YELLOW}⊘ .venv/$version (not created)${NC}")
        fi
        echo ""
    done
    
    # Summary
    print_header "Test Results Summary"
    for result in "${results[@]}"; do
        echo -e "$result"
    done
    echo ""
    print_info "Passed: $success | Failed: $failed"
    
    if [ $failed -eq 0 ] && [ $success -gt 0 ]; then
        print_success "All tests passed!"
        return 0
    else
        if [ $failed -gt 0 ]; then
            print_error "$failed environment(s) failed tests"
            return 1
        fi
    fi
}

# Clean up venvs
clean_venvs() {
    print_header "Cleaning Virtual Environments"
    echo ""
    
    read -p "Remove all .venv/* directories? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return 0
    fi
    
    local removed=0
    for version in "${PYTHON_VERSIONS[@]}"; do
        local venv_path="$VENV_BASE_DIR/$version"
        if [ -d "$venv_path" ]; then
            print_section "Removing .venv/$version"
            rm -rf "$venv_path"
            print_success "Removed"
            removed=$((removed + 1))
        fi
    done
    
    echo ""
    print_info "Removed $removed environment(s)"
}

# Main command handler
main() {
    local command="${1:-help}"
    local version_arg="${2:-}"
    
    # Ensure .venv directory exists
    mkdir -p "$VENV_BASE_DIR"
    
    case "$command" in
        create)
            if [ -z "$version_arg" ]; then
                create_all_venvs
            else
                print_header "Creating Virtual Environment"
                echo ""
                create_venv "$version_arg"
            fi
            ;;
        test)
            if [ -z "$version_arg" ]; then
                run_all_tests
            else
                print_header "Running Tests"
                echo ""
                run_tests_in_venv "$version_arg"
            fi
            ;;
        clean)
            clean_venvs
            ;;
        list)
            list_python_versions
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
