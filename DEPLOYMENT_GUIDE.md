# Django-Nine-v2 Deployment Guide

Complete guide for managing virtual environments, testing, and deploying django-nine-v2 to PyPI.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Available Scripts](#available-scripts)
4. [Workflow: Making Changes to Production](#workflow-making-changes-to-production)
5. [Detailed Script Documentation](#detailed-script-documentation)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The django-nine-v2 project uses three main bash scripts to manage the complete development and deployment lifecycle:

1. **test_envs.sh** — Create and manage Python 3.10-3.14 virtual environments
2. **deploy.sh** — Build packages and deploy to TestPyPI or Production PyPI
3. **check_pypi.sh** — Verify package versions on PyPI servers

These scripts work together to provide a complete CI/CD-like workflow that can run locally.

---

## Prerequisites

Before using these scripts, ensure you have:

### Required Software
```bash
# macOS
brew install uv         # Package installer and virtualenv manager
# Already installed: python, git, curl

# Linux
apt install uv curl    # Debian/Ubuntu
pacman -S uv curl      # Arch
```

### Configuration Files

**~/.pypirc** — PyPI authentication tokens
```ini
[distutils]
index-servers =
    testpypi
    pypi

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-AgEIcHlwaS5vcmc...  # Your TestPyPI token

[pypi]
repository = https://upload.pypi.org/legacy/
username = __token__
password = pypi-AgEIcHlwaS5vcmc...  # Your Production PyPI token
```

**GitHub Repository** — Required for production deployments
- Must be set up at: `https://github.com/JahanzebNawaz/django-nine-v2`
- Local git must be configured:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

---

## Available Scripts

### Quick Reference

| Script | Location | Purpose | Usage |
|--------|----------|---------|-------|
| test_envs.sh | scripts/test_envs.sh | Create/manage venvs, run tests | `./scripts/test_envs.sh [create\|test\|clean\|list]` |
| deploy.sh | scripts/deploy.sh | Build and deploy packages | `./scripts/deploy.sh [build\|test\|prod]` |
| check_pypi.sh | scripts/check_pypi.sh | Check versions on PyPI | `./scripts/check_pypi.sh [test\|prod\|all]` |

---

## Workflow: Making Changes to Production

This section shows the **complete workflow** from making code changes to having your package live on PyPI.

### Step 1: Make Code Changes

Edit your source code in `src/django_nine/`:
```bash
# Example: Edit a file
vim src/django_nine/versions.py

# Commit changes to git
git add src/django_nine/versions.py
git commit -m "Fix version detection for Django 6.0"
```

### Step 2: Update Version Number

Update `setup.py` with new version:
```bash
# Edit setup.py
vim setup.py

# Change version from "0.2.8" to "0.2.9"
# version = "0.2.9"

git add setup.py
git commit -m "Bump version to 0.2.9"
```

### Step 3: Create Virtual Environment (if needed)

```bash
# Create venv for your preferred Python version
./scripts/test_envs.sh create 312

# Or create all venvs
./scripts/test_envs.sh create

# List available venvs
./scripts/test_envs.sh list
```

**Output:**
```
>>> Creating .venv/312
ℹ Creating venv with Python 3.12 using uv...
✓ Created /Users/jayz/Documents/WORK/django-nine-v2/.venv/312
ℹ Installing project, dependencies, and test requirements...
✓ .venv/312 ready
```

### Step 4: Run Tests Locally

Test in a specific venv:
```bash
./scripts/test_envs.sh test 312
```

Or test in all venvs:
```bash
./scripts/test_envs.sh test
```

**Output:**
```
>>> Testing with Python 312 (.venv/312)
ℹ Python: Python 3.12.0
collected 18 items
src/django_nine/tests/test_versions.py ..................                [100%]
✓ Tests passed in .venv/312
```

### Step 5: Build Distribution Packages

Build packages using your preferred Python version:

```bash
# Build with Python 3.12
./scripts/deploy.sh build 312
```

**Or skip tests if you've already tested locally:**
```bash
SKIP_TESTS=1 ./scripts/deploy.sh build 312
```

**Output:**
```
ℹ django-nine-v2 version: 0.2.9
ℹ Using virtual environment: .venv/312
✓ .venv/312 found
>>> Activating .venv/312
✓ Activated: Python 3.12.0
✓ Tests passed
✓ Build completed
ℹ Created packages:
-rw-r--r--  25K django_nine_v2-0.2.9-py2.py3-none-any.whl
-rw-r--r--  21K django_nine_v2-0.2.9.tar.gz
```

### Step 6: Deploy to TestPyPI (Testing)

Upload packages to TestPyPI for testing before production:

```bash
# Deploy to TestPyPI
./scripts/deploy.sh test 312
```

**Interactive prompt:**
```
⚠ Ready to upload to TestPyPI
ℹ Packages to upload:
-rw-r--r--  25K django_nine_v2-0.2.9-py2.py3-none-any.whl
-rw-r--r--  21K django_nine_v2-0.2.9.tar.gz

Do you want to proceed with uploading to TestPyPI? (yes/no): yes
```

**Output:**
```
✓ TestPyPI deployment completed
ℹ Test installation command:
  pip install -i https://test.pypi.org/simple/ django-nine-v2
```

### Step 7: Verify TestPyPI Upload

Check that your package is on TestPyPI:

```bash
# Check TestPyPI only
./scripts/check_pypi.sh test

# Compare TestPyPI vs Production
./scripts/check_pypi.sh all
```

**Output:**
```
========================================
Checking TestPyPI
========================================
✓ Latest version: 0.2.9
ℹ All available versions:
  → 0.2.8
  → 0.2.9
ℹ PyPI Link: https://test.pypi.org/project/django-nine-v2/
```

### Step 8: Test Installation from TestPyPI

Verify the package works:

```bash
# Create a test environment
python3 -m venv /tmp/test_venv
source /tmp/test_venv/bin/activate

# Install from TestPyPI
pip install -i https://test.pypi.org/simple/ django-nine-v2

# Test import
python -c "import django_nine; print(django_nine.__version__)"
```

### Step 9: Deploy to Production PyPI

**⚠️ This is the final step. After this, your package is live!**

```bash
# Deploy to Production
./scripts/deploy.sh prod 312
```

**Interactive prompt - Single Confirmation:**

```
⚠ FINAL APPROVAL REQUIRED: Ready to upload to Production PyPI
ℹ Version: 0.2.9
ℹ Packages to upload:
-rw-r--r--  25K django_nine_v2-0.2.9-py2.py3-none-any.whl
-rw-r--r--  21K django_nine_v2-0.2.9.tar.gz

Do you want to proceed with uploading to PRODUCTION PyPI? (yes/no): yes
```

**Output:**
```
Step 1: Creating Git Tag
ℹ Creating git tag: v0.2.9

Step 2: Building Distribution Packages
✓ Build completed

Step 3: Deploying to Production PyPI
✓ Production PyPI deployment completed

Step 4: Pushing Git Tag to GitHub
✓ Git tag pushed successfully

========================================
Deployment Complete! ✓
========================================
ℹ Version: 0.2.9
ℹ Installation command: pip install django-nine-v2
ℹ GitHub tag: https://github.com/JahanzebNawaz/django-nine-v2/releases/tag/v0.2.9
```

### Step 10: Verify Production PyPI

Confirm the package is on Production PyPI:

```bash
# Check Production PyPI
./scripts/check_pypi.sh prod

# Compare both servers
./scripts/check_pypi.sh all
```

**Output:**
```
========================================
Checking Production PyPI
========================================
✓ Latest version: 0.2.9
ℹ All available versions (last 10):
  → 0.2.8
  → 0.2.9
ℹ PyPI Link: https://pypi.org/project/django-nine-v2/
```

### Step 11: Announce Release

Your package is now live! Users can install with:

```bash
pip install django-nine-v2
```

---

## Detailed Script Documentation

### test_envs.sh — Virtual Environment Manager

**Location:** `scripts/test_envs.sh`

**Purpose:** Create and manage Python 3.10-3.14 virtual environments using `uv`.

**Make it executable:**
```bash
chmod +x scripts/test_envs.sh
```

**Commands:**

#### Create all venvs
```bash
./scripts/test_envs.sh create
```
Creates `.venv/310`, `.venv/311`, `.venv/312`, `.venv/313`, `.venv/314`

Each venv includes:
- Project source code (`-e .`)
- pytest, pytest-cov (testing)
- beautifulsoup4 (dependencies)
- tox, build, twine (deployment tools)

#### Create specific venv
```bash
./scripts/test_envs.sh create 312
```

#### List available Python versions
```bash
./scripts/test_envs.sh list
```

Shows which Python versions are available locally or downloadable via `uv`.

#### Run tests in specific venv
```bash
./scripts/test_envs.sh test 312
```

Runs `runtests.py` (pytest) with coverage reporting.

#### Run tests in all venvs
```bash
./scripts/test_envs.sh test
```

Useful for matrix testing across multiple Python versions.

#### Clean up all venvs
```bash
./scripts/test_envs.sh clean
```

Removes all `.venv/3xx` directories (requires confirmation).

---

### deploy.sh — Build and Deploy

**Location:** `scripts/deploy.sh`

**Purpose:** Build distribution packages and deploy to PyPI.

**Make it executable:**
```bash
chmod +x scripts/deploy.sh
```

**Commands:**

#### Build packages only
```bash
./scripts/deploy.sh build [PYTHON_VERSION]
```

Examples:
```bash
./scripts/deploy.sh build          # Use system Python
./scripts/deploy.sh build 312      # Use .venv/312
SKIP_TESTS=1 ./scripts/deploy.sh build 312  # Skip tests
```

**What it does:**
1. Activates specified venv (if provided)
2. Runs tests (unless `SKIP_TESTS=1`)
3. Cleans old builds (`dist/`, `build/`, `*.egg-info`)
4. Runs `tox -e build`:
   - Builds wheel (`.whl`)
   - Builds source distribution (`.tar.gz`)
   - Validates with `twine check`

**Output files:** `dist/django_nine_v2-0.2.9-py2.py3-none-any.whl` and `dist/django_nine_v2-0.2.9.tar.gz`

#### Deploy to TestPyPI
```bash
./scripts/deploy.sh test [PYTHON_VERSION]
```

Examples:
```bash
./scripts/deploy.sh test 312
./scripts/deploy.sh test           # Use system Python
```

**What it does:**
1. Builds packages (or uses existing ones)
2. Shows packages to upload
3. Prompts for confirmation (must type `yes`)
4. Uploads to TestPyPI using `tox -e deploy-test`
5. Shows test installation command

**Installation command provided:**
```
pip install -i https://test.pypi.org/simple/ django-nine-v2
```

#### Deploy to Production PyPI
```bash
./scripts/deploy.sh prod [PYTHON_VERSION]
```

Examples:
```bash
./scripts/deploy.sh prod 312
./scripts/deploy.sh prod           # Use system Python
```

**⚠️ This is permanent! Once pushed, it's live on PyPI.**

**What it does:**
1. Builds packages (or uses existing ones)
2. **Step 1:** Creates git tag `v0.2.9`
   - If tag exists, offers to delete and recreate
   - If working directory dirty, offers to stash changes
3. **Step 2:** Builds distribution packages
4. **Step 3:** Prompts for final approval (must type `yes`)
5. **Step 3:** Uploads to Production PyPI using `tox -e deploy`
6. **Step 4:** Pushes git tag to GitHub

**Failure handling:**
- If tag creation fails → abort immediately
- If build fails → tag stays local (can delete with `git tag -d v0.2.9`)
- If upload fails → tag stays local (can delete and retry)
- If push fails → upload succeeded, manually push tag with `git push origin v0.2.9`

---

### check_pypi.sh — Verify Deployments

**Location:** `scripts/check_pypi.sh`

**Purpose:** Check package versions on PyPI servers using the JSON API.

**Make it executable:**
```bash
chmod +x scripts/check_pypi.sh
```

**Commands:**

#### Check TestPyPI versions
```bash
./scripts/check_pypi.sh test
```

**Output:**
```
========================================
Checking TestPyPI
========================================
✓ Latest version: 0.2.9
ℹ All available versions:
  → 0.2.8
  → 0.2.9
ℹ PyPI Link: https://test.pypi.org/project/django-nine-v2/
```

#### Check Production PyPI versions
```bash
./scripts/check_pypi.sh prod
```

**Output:**
```
========================================
Checking Production PyPI
========================================
✓ Latest version: 0.2.9
ℹ All available versions (last 10):
  → 0.2.8
  → 0.2.9
ℹ PyPI Link: https://pypi.org/project/django-nine-v2/
```

#### Compare both servers
```bash
./scripts/check_pypi.sh all
```

**Output:**
```
========================================
Comparing Versions: TestPyPI vs Production
========================================

TestPyPI           Production PyPI
─────────────────────────────────────────
0.2.9               0.2.9           

✓ Versions are in sync

ℹ TestPyPI: https://test.pypi.org/project/django-nine-v2/
ℹ Production: https://pypi.org/project/django-nine-v2/
```

**Use cases:**
- Verify upload succeeded after deployment
- Check if new version is available
- Compare TestPyPI and Production versions
- Debug deployment issues

---

## Troubleshooting

### Virtual Environment Issues

**Problem:** `Virtual environment not found: .venv/312`

**Solution:**
```bash
./scripts/test_envs.sh create 312
```

**Problem:** `Python 3.12 not found`

**Solution:**
`uv` can automatically download Python versions:
```bash
# Check available versions
./scripts/test_envs.sh list

# Create venv - uv will download if needed
./scripts/test_envs.sh create 312
```

---

### Deployment Issues

**Problem:** `tox is not installed`

**Solution:** Tox is installed in venvs created by `test_envs.sh`. Use:
```bash
./scripts/deploy.sh build 312  # Activate .venv/312 which has tox
```

**Problem:** `.pypirc not found. PyPI uploads may fail`

**Solution:** Create `~/.pypirc` with your PyPI tokens (see [Prerequisites](#prerequisites)).

---

### PyPI Upload Issues

**Problem:** `TestPyPI deployment failed` or `Production deployment failed`

**Solution:**
1. Verify `.pypirc` has correct tokens
2. Check network connection
3. Check package metadata: `twine check dist/*`
4. Recreate venv and rebuild: 
   ```bash
   rm -rf .venv/312
   ./scripts/test_envs.sh create 312
   ./scripts/deploy.sh build 312
   ```

**Problem:** Git tag push failed but PyPI upload succeeded

**Solution:** Manually push the tag:
```bash
git push origin v0.2.9
```

---

### Verification Issues

**Problem:** `Package not found on PyPI`

**Solution:**
- After TestPyPI upload: Wait 30 seconds for index to update
- Check correct package name: `django-nine-v2`
- Check network: `curl -s https://test.pypi.org/pypi/django-nine-v2/json | head`

---

## Quick Reference Commands

```bash
# Create venvs
./scripts/test_envs.sh create

# Test code
./scripts/test_envs.sh test 312

# Build locally
./scripts/deploy.sh build 312

# Deploy to TestPyPI
./scripts/deploy.sh test 312

# Deploy to Production
./scripts/deploy.sh prod 312

# Check versions
./scripts/check_pypi.sh all

# Full workflow in one go (with prompts)
./scripts/test_envs.sh create 312  # Create venv
./scripts/test_envs.sh test 312    # Run tests
./scripts/deploy.sh prod 312       # Deploy to prod (with confirmations)
./scripts/check_pypi.sh all        # Verify
```

---

## Environment Variables

### SKIP_TESTS

Skip test execution when building:

```bash
SKIP_TESTS=1 ./scripts/deploy.sh build 312
```

Useful when you've already tested locally and want faster builds.

---

## Git Integration

All production deployments create git tags:

```bash
# View tags
git tag

# View specific tag
git show v0.2.9

# Push all tags
git push origin --tags
```

Tags follow the format: `v{VERSION}` (e.g., `v0.2.9`)

---

## File Locations

```
django-nine-v2/
├── scripts/
│   ├── test_envs.sh          # Virtual environment manager
│   ├── deploy.sh             # Build and deploy
│   └── check_pypi.sh         # Check PyPI versions
├── src/
│   └── django_nine/          # Source code
├── setup.py                  # Package metadata and version
├── DEPLOYMENT_GUIDE.md       # This file
└── .venv/
    ├── 310/                  # Python 3.10 venv
    ├── 311/                  # Python 3.11 venv
    ├── 312/                  # Python 3.12 venv
    ├── 313/                  # Python 3.13 venv
    └── 314/                  # Python 3.14 venv
```

---

## Summary

**For any change:**

1. Edit code in `src/django_nine/`
2. Update version in `setup.py`
3. Run tests: `./scripts/test_envs.sh test 312`
4. Build: `./scripts/deploy.sh build 312`
5. Test upload: `./scripts/deploy.sh test 312`
6. Verify: `./scripts/check_pypi.sh test`
7. Production: `./scripts/deploy.sh prod 312`
8. Verify: `./scripts/check_pypi.sh all`

Each step has built-in safeguards and prompts to prevent mistakes!
