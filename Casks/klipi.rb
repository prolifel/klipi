cask "klipi" do
  version "1.0.0"
  sha256 "PLACEHOLDER_CHECKSUM"

  url "https://github.com/prolifel/klipi/releases/download/v#{version}/Klipi-#{version}.dmg"
  name "Klipi"
  desc "Clipboard history manager for menu bar"
  homepage "https://github.com/prolifel/klipi"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Klipi.app"

  zap trash: [
    "~/Library/Application Support/Klipi",
    "~/Library/Preferences/com.klipi.app.plist",
  ]
end