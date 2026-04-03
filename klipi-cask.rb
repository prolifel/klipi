cask "klipi" do
  version "1.0.13"
  sha256 "<REPLACE_WITH_DMG_SHA256>"

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

  zap trash: [
    "~/Library/Preferences/com.klipi.app.plist",
    "~/Library/Application Support/Klipi",
  ]
end
