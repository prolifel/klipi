# Klipi Release Guide

This document explains how to publish Klipi to Homebrew using GitHub Actions for automated releases.

## Overview

The release process:
1. Push a version tag (e.g., `v1.0.0`) to GitHub
2. GitHub Actions automatically builds the app and creates a DMG
3. A GitHub Release is created with the DMG file
4. Submit to Homebrew Cask (one-time setup)

---

## Prerequisites

### 1. GitHub Repository Setup

```bash
# Add remote if not already configured
git remote add origin https://github.com/YOUR_USERNAME/klipi.git

# Push main branch
git push -u origin main
```

### 2. Enable GitHub Actions

- Go to your repo → Settings → Actions → General
- Ensure "Read and write permissions" is selected for workflow permissions

---

## Creating a Release

### Step 1: Update Version

Update version numbers in:
- `Info.plist`: `CFBundleShortVersionString` and `CFBundleVersion`

### Step 2: Commit and Tag

```bash
# Commit any changes
git add .
git commit -m "Bump version to 1.0.0"

# Create and push tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

### Step 3: Verify Build

- Go to your repo → Actions tab
- Monitor the build progress
- Check that the release was created under Releases

---

## Code Signing (Optional but Recommended)

For proper code signing and notarization, add these secrets to your repository:

### Required Secrets

Go to Settings → Secrets and variables → Actions

| Secret Name | Description |
|-------------|-------------|
| `APPLE_CERTIFICATES_P12` | Base64 encoded .p12 certificate |
| `APPLE_CERTIFICATES_PASSWORD` | Password for .p12 file |
| `KEYCHAIN_PASSWORD` | Temporary keychain password |
| `APPLE_ID` | Your Apple ID email |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID |
| `APPLE_APP_PASSWORD` | App-specific password for notarization |

### Update Workflow for Signing

Add this step after "Build app" in `.github/workflows/release.yml`:

```yaml
- name: Install Apple Certificate
  if: ${{ env.APPLE_CERTIFICATES_P12 != '' }}
  env:
    CERTIFICATES_P12: ${{ secrets.APPLE_CERTIFICATES_P12 }}
    CERTIFICATES_PASSWORD: ${{ secrets.APPLE_CERTIFICATES_PASSWORD }}
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    # Create temporary keychain
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
    security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

    # Import certificate
    CERTIFICATE_PATH=$RUNNER_TEMP/certificate.p12
    echo -n "$CERTIFICATES_P12" | base64 --decode -o $CERTIFICATE_PATH
    security import $CERTIFICATE_PATH -P "$CERTIFICATES_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
    security list-keychain -d user -s $KEYCHAIN_PATH
```

---

## Homebrew Cask Setup

### Step 1: Get SHA256 Checksum

After creating a release, download the checksum:

```bash
curl -L https://github.com/YOUR_USERNAME/klipi/releases/download/v1.0.0/checksum.txt
```

### Step 2: Create Cask Formula

Create `klipi.rb`:

```ruby
cask "klipi" do
  version "1.0.0"
  sha256 "CHECKSUM_FROM_RELEASE"

  url "https://github.com/YOUR_USERNAME/klipi/releases/download/v#{version}/Klipi-#{version}.dmg"
  name "Klipi"
  desc "Clipboard history manager for macOS menu bar"
  homepage "https://github.com/YOUR_USERNAME/klipi"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "Klipi.app"

  zap trash: [
    "~/Library/Preferences/com.klipi.app.plist",
    "~/Library/Application Support/Klipi",
  ]
end
```

### Step 3: Test Locally

```bash
# Install from local cask file
brew install --cask ./klipi.rb

# Test the app
open /Applications/Klipi.app

# Uninstall
brew uninstall --cask klipi
```

### Step 4: Submit to Homebrew

1. Fork https://github.com/Homebrew/homebrew-cask
2. Add `Casks/k/klipi.rb` to your fork
3. Create a pull request

**PR Title format:** `klipi #{version} (new formula)`

**PR Description example:**
```
Add Klipi, a clipboard history manager for macOS.

- [x] `brew audit --cask --online klipi` passes
- [x] `brew style --cask klipi` passes
```

---

## Updating a Release

### Step 1: Bump Version

```bash
# Update version in Info.plist
# Then commit and tag
git add .
git commit -m "Bump version to 1.1.0"
git tag v1.1.0
git push origin main --tags
```

### Step 2: Update Homebrew Cask

```bash
# Use brew bump to update the cask
brew bump-cask-pr klipi --version 1.1.0
```

Or manually update the cask file and create a PR.

---

## Workflow File Reference

The GitHub Actions workflow (`.github/workflows/release.yml`) does:

1. **Triggers** on version tags (`v*`)
2. **Builds** the macOS app using Xcode
3. **Creates** a DMG installer
4. **Generates** SHA256 checksum
5. **Creates** GitHub Release with artifacts

---

## Troubleshooting

### Build Fails

```bash
# Test build locally first
xcodebuild -project Klipi.xcodeproj -scheme Klipi -configuration Release
```

### DMG Creation Fails

- Ensure the app builds successfully
- Check that `build/Build/Products/Release/Klipi.app` exists

### GitHub Actions Permission Denied

- Go to Settings → Actions → General
- Enable "Read and write permissions"

### Homebrew Cask Rejected

- Ensure app is code-signed and notarized
- Follow Homebrew contribution guidelines
- Use proper naming conventions

---

## Quick Reference

| Task | Command |
|------|---------|
| Create tag | `git tag v1.0.0` |
| Push tag | `git push origin v1.0.0` |
| Get checksum | `shasum -a 256 file.dmg` |
| Test cask locally | `brew install --cask ./klipi.rb` |
| Bump cask version | `brew bump-cask-pr klipi --version 1.1.0` |

---

## Next Steps

1. [ ] Create GitHub repository
2. [ ] Push code to GitHub
3. [ ] Create first release tag
4. [ ] Verify GitHub Actions build succeeds
5. [ ] Fork homebrew-cask
6. [ ] Submit PR with cask formula