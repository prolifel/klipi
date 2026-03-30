cask "klipi" do
  version "1.0.5"
  sha256 "73b0a82d80c2f72e2abf086c49d3a75c9cbe3c5ef0944d9ffbb1a7a582959efc"

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