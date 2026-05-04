#!/bin/bash

##############################################################################
# Check PyPI Version Script
# Checks available versions of django-nine-v2 on both TestPyPI and production
#
# Usage:
#   ./scripts/check_pypi.sh              # Show help
#   ./scripts/check_pypi.sh test         # Check TestPyPI versions
#   ./scripts/check_pypi.sh prod         # Check Production PyPI versions
#   ./scripts/check_pypi.sh all          # Check both TestPyPI and production
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PACKAGE_NAME="django-nine-v2"
TESTPYPI_URL="https://test.pypi.org/pypi/$PACKAGE_NAME/json"
PRODUCTION_URL="https://pypi.org/pypi/$PACKAGE_NAME/json"

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

print_version() {
    echo -e "${CYAN}  → $1${NC}"
}

show_help() {
    cat << EOF
Usage: ./scripts/check_pypi.sh [COMMAND]

Commands:
  help      Show this help message
  test      Check versions on TestPyPI
  prod      Check versions on Production PyPI
  all       Check versions on both TestPyPI and Production

Examples:
  ./scripts/check_pypi.sh test
    Show all available versions on TestPyPI

  ./scripts/check_pypi.sh prod
    Show all available versions on Production PyPI

  ./scripts/check_pypi.sh all
    Compare versions on both servers

Notes:
  - Requires internet connection to query PyPI
  - Uses PyPI JSON API for accurate data
  - Shows latest version and all available versions

EOF
}

# Check TestPyPI
check_test_pypi() {
    print_header "Checking TestPyPI"
    echo ""
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        return 1
    fi
    
    print_info "Querying TestPyPI API: $TESTPYPI_URL"
    echo ""
    
    local response
    response=$(curl -s "$TESTPYPI_URL" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        print_error "Failed to connect to TestPyPI"
        return 1
    fi
    
    # Check if response contains releases
    if ! echo "$response" | grep -q "\"releases\""; then
        print_error "Package not found on TestPyPI"
        return 1
    fi
    
    # Extract latest version using jq if available, otherwise use grep/cut
    local latest_version
    if command -v jq &> /dev/null; then
        latest_version=$(echo "$response" | jq -r '.info.version // empty' 2>/dev/null)
        if [ -n "$latest_version" ]; then
            print_success "Latest version: $latest_version"
            print_info "All available versions:"
            echo "$response" | jq -r '.releases | keys[]' 2>/dev/null | sort -V | while read -r version; do
                print_version "$version"
            done
        fi
    else
        # Fallback: extract from releases section
        latest_version=$(echo "$response" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9a-z.]*"' | head -1 | tr -d '"')
        if [ -n "$latest_version" ]; then
            print_success "Latest version: $latest_version"
            print_info "All available versions:"
            echo "$response" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9a-z.]*"' | tr -d '"' | sort -V -u | tail -10 | while read -r version; do
                print_version "$version"
            done
        else
            print_error "Could not parse version information"
            return 1
        fi
    fi
    
    echo ""
    print_info "PyPI Link: https://test.pypi.org/project/$PACKAGE_NAME/"
    return 0
}

# Check Production PyPI
check_prod_pypi() {
    print_header "Checking Production PyPI"
    echo ""
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        return 1
    fi
    
    print_info "Querying Production PyPI API: $PRODUCTION_URL"
    echo ""
    
    local response
    response=$(curl -s "$PRODUCTION_URL" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        print_error "Failed to connect to Production PyPI"
        return 1
    fi
    
    # Check if response contains releases
    if ! echo "$response" | grep -q "\"releases\""; then
        print_error "Package not found on Production PyPI"
        return 1
    fi
    
    # Extract latest version using jq if available, otherwise use grep/cut
    local latest_version
    if command -v jq &> /dev/null; then
        latest_version=$(echo "$response" | jq -r '.info.version // empty' 2>/dev/null)
        if [ -n "$latest_version" ]; then
            print_success "Latest version: $latest_version"
            print_info "All available versions (last 10):"
            echo "$response" | jq -r '.releases | keys[]' 2>/dev/null | sort -V | tail -10 | while read -r version; do
                print_version "$version"
            done
        fi
    else
        # Fallback: extract from releases section
        latest_version=$(echo "$response" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9a-z.]*"' | head -1 | tr -d '"')
        if [ -n "$latest_version" ]; then
            print_success "Latest version: $latest_version"
            print_info "All available versions (last 10):"
            echo "$response" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9a-z.]*"' | tr -d '"' | sort -V -u | tail -10 | while read -r version; do
                print_version "$version"
            done
        else
            print_error "Could not parse version information"
            return 1
        fi
    fi
    
    echo ""
    print_info "PyPI Link: https://pypi.org/project/$PACKAGE_NAME/"
    return 0
}

# Compare versions
check_all_pypi() {
    print_header "Comparing Versions: TestPyPI vs Production"
    echo ""
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        return 1
    fi
    
    local test_response prod_response
    
    print_info "Querying TestPyPI..."
    test_response=$(curl -s "$TESTPYPI_URL" 2>/dev/null)
    
    print_info "Querying Production PyPI..."
    prod_response=$(curl -s "$PRODUCTION_URL" 2>/dev/null)
    
    echo ""
    
    if [ -z "$test_response" ] || [ -z "$prod_response" ]; then
        print_error "Failed to connect to one or both PyPI servers"
        return 1
    fi
    
    # Extract latest versions using jq if available
    local test_version prod_version
    
    if command -v jq &> /dev/null; then
        test_version=$(echo "$test_response" | jq -r '.info.version // empty' 2>/dev/null)
        prod_version=$(echo "$prod_response" | jq -r '.info.version // empty' 2>/dev/null)
    else
        # Fallback parsing
        test_version=$(echo "$test_response" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9a-z.]*"' | head -1 | tr -d '"')
        prod_version=$(echo "$prod_response" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9a-z.]*"' | head -1 | tr -d '"')
    fi
    
    if [ -z "$test_version" ]; then
        test_version="Not Found"
    fi
    
    if [ -z "$prod_version" ]; then
        prod_version="Not Found"
    fi
    
    # Display comparison
    echo -e "${CYAN}TestPyPI${NC}           ${CYAN}Production PyPI${NC}"
    echo "─────────────────────────────────────────"
    printf "%-20s%-20s\n" "$test_version" "$prod_version"
    echo ""
    
    # Check if versions match
    if [ "$test_version" = "$prod_version" ]; then
        print_success "Versions are in sync"
    else
        if [ "$test_version" = "Not Found" ] || [ "$prod_version" = "Not Found" ]; then
            print_warning "Package not yet deployed to all servers"
        else
            print_warning "Versions differ - upgrade available"
        fi
    fi
    
    echo ""
    print_info "TestPyPI: https://test.pypi.org/project/$PACKAGE_NAME/"
    print_info "Production: https://pypi.org/project/$PACKAGE_NAME/"
}

# Main
main() {
    local command="${1:-help}"
    
    case "$command" in
        help)
            show_help
            ;;
        test)
            check_test_pypi
            ;;
        prod)
            check_prod_pypi
            ;;
        all)
            check_all_pypi
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
