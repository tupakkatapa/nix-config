{pkgs, ...}: {
  # Timezone and system version
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = 4;

  # Font packages
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    jetbrains-mono
  ];

  services.nix-daemon.enable = true;
  networking.hostName = "hyperion";
  environment.shells = [pkgs.fish];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    taps = [
      "homebrew/cask"
      "homebrew/cask-fonts"
    ];
    brews = [];
    casks = [
      "android-commandlinetools"
      "android-platform-tools"
      "whatsapp"
      "plexamp"
      "plex"
      "runelite"
      "sublime-merge"
      "font-iosevka"
      "obsidian"
      "element"
      "signal"
    ];
    masApps = {};
  };

  security.pam.enableSudoTouchIdAuth = true;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
}
