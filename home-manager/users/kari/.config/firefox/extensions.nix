# https://nur.nix-community.org/repos/rycee/
addons: with addons; [
  # Navigation & Productivity
  vimium
  bitwarden

  # Privacy & Security
  ublock-origin
  clearurls
  privacy-badger
  i-dont-care-about-cookies

  # YouTube
  youtube-shorts-block
  sponsorblock

  # Media & Downloads
  torrent-control

  # Appearance
  dark-background-light-text
  (buildFirefoxXpiAddon {
    pname = "gruvbox-medium-dark";
    version = "2.0";
    addonId = "{7c4b7a20-26d8-4788-a840-71fa26d332e0}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3792120/gruvbox_medium_dark-2.0.xpi";
    sha256 = "903b4dfb8ba218b4152ba6fc27d752a6b3ef8f447f7b39d87a1baaa0dbba515d";
    meta = { };
  })
]
