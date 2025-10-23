# Running GitHub Actions Locally with Act

This guide shows you how to run GitHub Actions workflows locally using [nektos/act](https://github.com/nektos/act).

## Prerequisites

### 1. Install Act

**macOS:**
```bash
brew install act
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### 2. Install Docker Desktop

Act runs workflows in Docker containers, so you need Docker running:
- Download from https://www.docker.com/products/docker-desktop
- Start Docker Desktop before running act

## Available Workflows

### 🚀 Quick Checks (Fast - No Emulator)
Runs formatting, analysis, and unit tests in ~2-3 minutes.

```bash
act workflow_dispatch -W .github/workflows/local-quick-checks.yml
```

**What it does:**
- ✅ Dart format check
- ✅ Flutter analyze
- ✅ Unit tests

### 🧪 Integration Tests (Slower - With Emulator)
Runs full Patrol integration tests with Android emulator in ~10-15 minutes.

```bash
act workflow_dispatch -W .github/workflows/patrol_local-checks.yml
```

**What it does:**
- ✅ Flutter analyze
- ✅ Sets up Android emulator
- ✅ Runs Patrol integration tests

## Configuration

### First Time Setup

Create a `.actrc` file in your project root to configure act:

```bash
cat > .actrc << 'EOF'
# Use medium-sized container for better compatibility
-P ubuntu-latest=catthehacker/ubuntu:act-latest

# Reuse containers for speed
--reuse

# Show verbose output
--verbose
EOF
```

### Environment Variables

The workflows automatically create a `.env` file with test values. If you need real credentials:

1. Create `.secrets` file in project root:
```bash
cat > .secrets << 'EOF'
COGNITO_USER_POOL_ID=your-real-pool-id
COGNITO_CLIENT_ID=your-real-client-id
API_BASE_URL=your-api-base-url
GEONAMES_USERNAME=your-username
EOF
```

2. Run act with secrets:
```bash
act workflow_dispatch -W .github/workflows/patrol_local-checks.yml --secret-file .secrets
```

## Common Commands

### List available workflows
```bash
act -l
```

### Run specific job
```bash
act workflow_dispatch -j quick_checks
```

### Run with custom container
```bash
act workflow_dispatch -P ubuntu-latest=catthehacker/ubuntu:full-latest
```

### Clean up containers
```bash
docker container prune -f
```

## Troubleshooting

### Docker Not Running
```
Error: Cannot connect to the Docker daemon
```
**Solution:** Start Docker Desktop

### Out of Disk Space
```bash
# Clean up Docker
docker system prune -a
```

### Emulator Issues

If the integration test workflow fails to start the emulator:

1. **Enable KVM on Linux:**
```bash
sudo apt install qemu-kvm
sudo adduser $USER kvm
```

2. **Increase Docker resources:**
   - Open Docker Desktop → Settings → Resources
   - Increase CPUs to 4+
   - Increase Memory to 8GB+

### Workflow Not Found
```
Error: unable to get git repo: unable to find HEAD
```
**Solution:** Make sure you're in the project root directory

## Performance Tips

### 1. Use Container Reuse
Add `--reuse` flag to keep containers between runs:
```bash
act workflow_dispatch --reuse
```

### 2. Cache Dependencies
The workflows use caching for:
- Flutter SDK
- Pub packages
- Android AVD

### 3. Skip Unnecessary Steps

Run only specific jobs:
```bash
# Quick checks only
act workflow_dispatch -W .github/workflows/local-quick-checks.yml

# Integration tests only  
act workflow_dispatch -W .github/workflows/patrol_local-checks.yml
```

## Differences from GitHub Actions

⚠️ **Important:** Some features work differently in act:

1. **Secrets:** Must be provided via `--secret-file` or `-s` flag
2. **Caching:** Works but stored locally in Docker volumes
3. **Artifacts:** Saved to `/tmp/artifacts` by default
4. **Matrix builds:** Fully supported
5. **GPU acceleration:** Limited (emulator runs in software mode)

## CI/CD Workflow

### Development Workflow

1. **Before committing:**
```bash
act workflow_dispatch -W .github/workflows/local-quick-checks.yml
```

2. **Before pushing:**
```bash
act workflow_dispatch -W .github/workflows/patrol_local-checks.yml
```

3. **Push to GitHub:**
The same workflows run automatically in CI

## Resources

- [Act Documentation](https://github.com/nektos/act)
- [Patrol CLI](https://patrol.leancode.co/)
- [Flutter GitHub Actions](https://docs.flutter.dev/deployment/cd#github-actions)

## Support

If you encounter issues:

1. Check Docker is running: `docker ps`
2. Verify act installation: `act --version`
3. Run with verbose output: `act --verbose`
4. Check logs in Docker: `docker logs <container-id>`
