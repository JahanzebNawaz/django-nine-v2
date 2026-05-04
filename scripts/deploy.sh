#!/bin/bash

##############################################################################
# Deploy script for django-nine-v2
# Builds distribution packages and uploads to PyPI (test or production)
#
# Usage:
#   ./scripts/deploy.sh              # Show help
#   ./scripts/deploy.sh build        # Build distribution packages only
#   ./scripts/deploy.sh test         # Build and deploy to TestPyPI
#   ./scripts/deploy.sh prod         # Build and deploy to production PyPI
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"

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

get_version() {
    # Extract version from setup.py
    python3 << EOF
import re
with open('$PROJECT_ROOT/setup.py') as f:
    content = f.read()
match = re.search(r'version\s*=\s*["\']([^"\']*)["\']', content)
print(match.group(1) if match else '')
EOF
}

check_git_repo() {
    # Check if we're in a git repository
    if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository. Git operations required for production deployment."
        return 1
    fi
    return 0
}

create_git_tag() {
    local version="$1"
    local tag="v${version}"

    print_info "Checking git status..."
    cd "$PROJECT_ROOT"

    # Check if tag already exists
    if git rev-parse "$tag" >/dev/null 2>&1; then
        print_warning "Git tag '$tag' already exists"
        read -p "Do you want to delete and recreate it? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            print_info "Deleting existing tag '$tag'"
            git tag -d "$tag" || true
            git push origin ":refs/tags/$tag" || true
        else
            print_warning "Skipping tag creation"
            return 0
        fi
    fi

    # Ensure working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Working directory has uncommitted changes"
        read -p "Do you want to stash them? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_error "Cannot proceed with uncommitted changes"
            return 1
        fi
        git stash
    fi

    print_info "Creating git tag: $tag"
    git tag -a "$tag" -m "Release version $version - django-nine-v2 fork" || {
        print_error "Failed to create git tag"
        return 1
    }
    print_success "Git tag '$tag' created"
    return 0
}

push_git_tag() {
    local version="$1"
    local tag="v${version}"

    print_info "Pushing git tag to GitHub..."
    cd "$PROJECT_ROOT"

    git push origin "$tag" || {
        print_error "Failed to push git tag to GitHub"
        return 1
    }
    print_success "Git tag '$tag' pushed to GitHub"
    return 0
}


show_help() {
    cat << EOF
Usage: ./scripts/deploy.sh [COMMAND] [PYTHON_VERSION]

Commands:
  help      Show this help message
  build     Build distribution packages (wheel + source tar.gz)
  test      Build and deploy to TestPyPI for testing
  prod      Build and deploy to production PyPI

Arguments:
  PYTHON_VERSION   Optional: Python version (310, 311, 312, 313, 314)
                   If specified, activates .venv/PYTHON_VERSION before deploying
                   If omitted, uses system Python directly

Environment Variables:
  SKIP_TESTS   Set to 1 to skip running tests before build (default: 0)

Examples:
  ./scripts/deploy.sh build
    Build packages using system Python and tox

  ./scripts/deploy.sh build 311
    Build packages using .venv/311 (Python 3.11 virtual environment)

  ./scripts/deploy.sh test
    Build and deploy to TestPyPI using system Python

  ./scripts/deploy.sh test 312
    Build and deploy to TestPyPI using .venv/312 (Python 3.12)

  ./scripts/deploy.sh prod
    Full deployment to production PyPI with system Python

  ./scripts/deploy.sh prod 311
    Full deployment to production PyPI using .venv/311

Notes:
  - If PYTHON_VERSION is specified, that venv must exist (created via ./scripts/test_envs.sh create)
  - Requires .pypirc configured with PyPI tokens
  - Tests run by default; set SKIP_TESTS=1 to skip
  - Production deployment creates git tag and pushes to GitHub
  - All commands use tox for consistency

EOF
}

check_requirements() {
    local python_version="$1"
    
    print_info "Checking requirements..."

    # If Python version specified, check if venv exists
    if [ -n "$python_version" ]; then
        local venv_path="$PROJECT_ROOT/.venv/$python_version"
        if [ ! -d "$venv_path" ]; then
            print_error "Virtual environment not found: .venv/$python_version"
            print_info "Create it with: ./scripts/test_envs.sh create $python_version"
            exit 1
        fi
        print_success ".venv/$python_version found"
        # Skip system tox check - tox will be in the venv
    else
        # Only check system tox if no venv specified
        if ! command -v tox &> /dev/null; then
            print_error "tox is not installed. Install with: pip install tox"
            exit 1
        fi
        print_success "tox is installed"
    fi

    # Check if .pypirc exists
    if [ ! -f ~/.pypirc ]; then
        print_warning ".pypirc not found. PyPI uploads may fail if tokens are not configured."
        print_info "Create ~/.pypirc with your PyPI tokens before deploying."
    else
        print_success ".pypirc found"
    fi

    # Check if setup.py exists
    if [ ! -f "$PROJECT_ROOT/setup.py" ]; then
        print_error "setup.py not found in project root"
        exit 1
    fi
    print_success "setup.py found"
}

activate_venv() {
    local python_version="$1"
    
    if [ -z "$python_version" ]; then
        return 0  # No venv to activate
    fi
    
    local venv_path="$PROJECT_ROOT/.venv/$python_version"
    
    print_section "Activating .venv/$python_version"
    
    if [ ! -d "$venv_path" ]; then
        print_error "Virtual environment not found: $venv_path"
        return 1
    fi
    
    # Source the activation script
    source "$venv_path/bin/activate"
    
    # Verify activation
    if ! python --version 2>&1 | grep -q "^Python"; then
        print_error "Failed to activate virtual environment"
        return 1
    fi
    
    local py_version=$(python --version 2>&1)
    print_success "Activated: $py_version"
    return 0
}

print_section() {
    echo -e "${MAGENTA}>>> $1${NC}"
}

run_tests() {
    if [ "$SKIP_TESTS" = "1" ]; then
        print_warning "Skipping tests (SKIP_TESTS=1)"
        return 0
    fi

    print_header "Running Tests"
    cd "$PROJECT_ROOT"
    python runtests.py || {
        print_error "Tests failed. Aborting deployment."
        exit 1
    }
    print_success "Tests passed"
}

build_packages() {
    print_header "Building Distribution Packages"
    cd "$PROJECT_ROOT"

    # Get and display version
    local version
    version=$(get_version)
    if [ -z "$version" ]; then
        print_error "Could not extract version from setup.py"
        exit 1
    fi
    print_info "Package version: $version"

    # Clean old builds
    print_info "Cleaning old builds..."
    rm -rf dist/ build/ *.egg-info 2>/dev/null || true
    print_success "Cleaned old builds"

    # Run tox build environment
    print_info "Running: tox -e build"
    tox -e build || {
        print_error "Build failed"
        exit 1
    }

    # List created packages
    print_success "Build completed"
    print_info "Created packages:"
    ls -lh dist/
}

deploy_test() {
    print_header "Deploying to TestPyPI"
    cd "$PROJECT_ROOT"

    if [ ! -d "dist" ] || [ -z "$(ls -A dist/)" ]; then
        print_warning "No distribution packages found. Building first..."
        build_packages
    fi

    # Final approval before upload
    echo ""
    print_warning "Ready to upload to TestPyPI"
    print_info "Packages to upload:"
    ls -lh dist/
    echo ""
    read -p "Do you want to proceed with uploading to TestPyPI? (yes/no): " approval
    
    if [ "$approval" != "yes" ]; then
        print_info "Upload cancelled"
        return 0
    fi

    print_info "Running: tox -e deploy-test"
    tox -e deploy-test || {
        print_error "TestPyPI deployment failed"
        exit 1
    }

    print_success "TestPyPI deployment completed"
    print_info "Test installation command:"
    echo "  pip install -i https://test.pypi.org/simple/ django-nine-v2"
}

deploy_prod() {
    print_header "Deploying to Production PyPI"
    print_warning "This will create a git tag, build, upload to PyPI, and push to GitHub!"
    echo ""

    # Get version
    local version
    version=$(get_version)
    if [ -z "$version" ]; then
        print_error "Could not extract version from setup.py"
        exit 1
    fi
    print_info "Deploying version: $version"
    echo ""

    # Check git repository
    if ! check_git_repo; then
        print_error "Production deployment requires a git repository"
        exit 1
    fi

    # Step 1: Create git tag FIRST
    print_header "Step 1: Creating Git Tag"
    if ! create_git_tag "$version"; then
        print_error "Git tag creation failed. Aborting deployment."
        exit 1
    fi

    # Step 2: Build packages
    print_header "Step 2: Building Distribution Packages"
    if [ -d "dist" ] && [ -n "$(ls -A dist/)" ]; then
        print_warning "Existing dist/ directory found. Cleaning..."
        rm -rf dist/ build/ *.egg-info 2>/dev/null || true
    fi
    
    build_packages || {
        print_error "Build failed. Git tag created but not pushed."
        print_warning "To delete the local tag, run: git tag -d v$version"
        exit 1
    }

    # Step 3: Deploy to PyPI
    print_header "Step 3: Deploying to Production PyPI"
    cd "$PROJECT_ROOT"
    
    # Final approval before production upload
    echo ""
    print_warning "FINAL APPROVAL REQUIRED: Ready to upload to Production PyPI"
    print_info "Version: $version"
    print_info "Packages to upload:"
    ls -lh dist/
    echo ""
    read -p "Do you want to proceed with uploading to PRODUCTION PyPI? (yes/no): " prod_approval
    
    if [ "$prod_approval" != "yes" ]; then
        print_info "Upload cancelled"
        print_warning "Git tag created locally but NOT pushed. To clean up, run: git tag -d v$version"
        return 0
    fi
    
    print_info "Running: tox -e deploy"
    tox -e deploy || {
        print_error "Production deployment failed. Git tag created but not pushed."
        print_warning "To delete the local tag, run: git tag -d v$version"
        exit 1
    }
    print_success "Production PyPI deployment completed"

    # Step 4: Push git tag to GitHub
    print_header "Step 4: Pushing Git Tag to GitHub"
    if push_git_tag "$version"; then
        print_success "Git tag pushed successfully"
    else
        print_error "Git tag push failed, but PyPI deployment succeeded"
        print_warning "Push manually with: git push origin v$version"
        exit 1
    fi

    print_header "Deployment Complete! ✓"
    print_success "All deployment steps completed successfully"
    print_info "Version: $version"
    print_info "Installation command: pip install django-nine-v2"
    print_info "GitHub tag: https://github.com/JahanzebNawaz/django-nine-v2/releases/tag/v$version"
}

# Main
main() {
    local command="${1:-help}"
    local python_version="${2:-}"

    # Display version info at startup (except for help)
    if [ "$command" != "help" ]; then
        local version
        version=$(get_version)
        if [ -n "$version" ]; then
            print_info "django-nine-v2 version: $version"
        fi
        
        # Show which environment will be used
        if [ -n "$python_version" ]; then
            print_info "Using virtual environment: .venv/$python_version"
        else
            print_info "Using system Python"
        fi
        echo ""
    fi

    case "$command" in
        help)
            show_help
            ;;
        build)
            check_requirements "$python_version"
            if [ -n "$python_version" ]; then
                activate_venv "$python_version" || exit 1
            fi
            run_tests
            build_packages
            print_success "Build complete! Packages are in dist/"
            ;;
        test)
            check_requirements "$python_version"
            if [ -n "$python_version" ]; then
                activate_venv "$python_version" || exit 1
            fi
            run_tests
            build_packages
            deploy_test
            ;;
        prod)
            check_requirements "$python_version"
            if [ -n "$python_version" ]; then
                activate_venv "$python_version" || exit 1
            fi
            run_tests
            build_packages
            deploy_prod
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
