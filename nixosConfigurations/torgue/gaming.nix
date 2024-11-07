{ pkgs
, ...
}: {
  imports = [
    ../.config/gaming-amd.nix
    ../.config/retroarch.nix
    ../.config/virtualization/wine.nix
  ];

  # High quality games
  environment.systemPackages = with pkgs; [
    runelite
    osu-lazer
    discord
  ];
  programs.anime-game-launcher.enable = true;
}


