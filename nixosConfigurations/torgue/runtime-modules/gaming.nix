{ pkgs
, ...
}: {
  imports = [
    ../../.config/gaming-amd.nix
  ];

  # High quality games
  environment.systemPackages = with pkgs; [
    runelite
    osu-lazer
    discord
  ];
  programs.anime-game-launcher.enable = true;
}


