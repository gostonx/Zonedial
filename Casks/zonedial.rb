cask "zonedial" do
  version "1.0.1"
  sha256 "6a0b7796fd7da3181c83e5d9e7ab99a9419a7d50750ece64e6d679fcd5a01f76"

  url "https://github.com/gostonx/Zonedial/releases/download/v#{version}/Zonedial.dmg"
  name "Zonedial"
  desc "Time-zone menu bar app for macOS"
  homepage "https://github.com/gostonx/Zonedial"

  depends_on macos: ">= :sonoma"

  app "Zonedial.app"

  zap trash: [
    "~/Library/Preferences/us.codenta.zonedial.plist",
  ]
end
