#!/bin/bash
# Migrate homebrew-tap from Formula to Cask

set -e

TAP_DIR="/tmp/homebrew-tap"
CASK_VERSION="1.0.13"

echo "=== Klipi Tap Migration Script ==="
echo ""

# Clean up any existing clone
rm -rf "$TAP_DIR"

# Clone the tap repo
echo "1. Cloning homebrew-tap repo..."
git clone https://github.com/prolifel/homebrew-tap.git "$TAP_DIR"
cd "$TAP_DIR"

# Create Casks directory
echo "2. Creating Casks directory..."
mkdir -p Casks

# Get the latest DMG checksum from GitHub releases
echo "3. Fetching latest release checksum..."
DMG_URL="https://github.com/prolifel/klipi/releases/download/v${CASK_VERSION}/Klipi-${CASK_VERSION}.dmg"

if curl --fail --silent --head "$DMG_URL" > /dev/null; then
    echo "   Downloading DMG for checksum..."
    curl -sL "$DMG_URL" -o "/tmp/klipi-${CASK_VERSION}.dmg"
    SHA256=$(shasum -a 256 "/tmp/klipi-${CASK_VERSION}.dmg" | cut -d' ' -f1)
    echo "   SHA256: $SHA256"
    rm "/tmp/klipi-${CASK_VERSION}.dmg"
else
    echo "   WARNING: Could not download DMG from $DMG_URL"
    echo "   Please update CASK_VERSION in this script or manually set the checksum"
    SHA256="<REPLACE_WITH_ACTUAL_SHA256>"
fi

# Write the cask file
echo "4. Writing Cask formula..."
cat > Casks/klipi.rb << 'EOF'
cask "klipi" do
  version "1.0.13"
  sha256 "<REPLACE_WITH_ACTUAL_SHA256>"

  url "https://github.com/prolifel/klipi/releases/download/v#{version}/Klipi-#{version}.dmg"
  name "Klipi"
  desc "Lightweight clipboard manager for macOS menu bar"
  homepage "https://github.com/prolifel/klipi"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "Klipi.app"

  uninstall quit: "com.klipi.app"

  postflight do
    app_link = "/Applications/Klipi.app"
    if File.exist?(app_link)
      FileUtils.rm(app_link)
    end
    FileUtils.ln_sf(appdir/"Klipi.app", app_link)
  rescue => e
    # Error handling moved to caveats
  end

  caveats do
    s = "Klipi has been installed to #{appdir}/Klipi.app\n\n"

    if File.symlink?("/Applications/Klipi.app")
      s += "A symlink has been created in /Applications.\n\n"
    else
      s += "\e[33mCould not create symlink in /Applications.\e[0m\n"
      s += "To add to Applications manually, run:\n"
      s += "  ln -sf #{appdir}/Klipi.app /Applications/Klipi.app\n\n"
    end

    s += "\e[32m==> IMPORTANT: Grant Input Monitoring permission!\e[0m\n"
    s += "    Without this permission, Klipi cannot monitor keyboard shortcuts.\n\n"
    s += "    Steps to enable:\n"
    s += "      1. Open System Settings → Privacy & Security → Input Monitoring\n"
    s += "      2. Click the + button\n"
    s += "      3. Navigate to /Applications/Klipi.app and select it\n"
    s += "      4. Restart Klipi\n\n"
    s += "To uninstall: run \e[34mklipi-uninstall\e[0m\n"
    s
  end

  zap trash: [
    "~/Library/Preferences/com.klipi.app.plist",
    "~/Library/Application Support/Klipi",
  ]
end
EOF

# Remove old Formula
echo "5. Removing old Formula..."
if [ -f "Formula/klipi.rb" ]; then
    rm Formula/klipi.rb
    echo "   Removed Formula/klipi.rb"
else
    echo "   Formula/klipi.rb not found, skipping"
fi

# Commit and push
echo "6. Committing changes..."
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"
git add Casks/klipi.rb
if [ -f "Formula/klipi.rb" ]; then
    git add Formula/klipi.rb
fi
git commit -m "Migrate klipi from Formula to Cask (pre-built binary)"

echo "7. Pushing to GitHub..."
git push origin main

echo ""
echo "=== Migration Complete! ==="
echo ""
echo "Users can now install Klipi with:"
echo "  brew install --cask prolifel/homebrew-tap/klipi"
echo ""
echo "Or after tapping:"
echo "  brew tap prolifel/homebrew-tap"
echo "  brew install --cask klipi"
