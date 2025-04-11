{ pkgs, ... }: {
  # High quality games
  environment.systemPackages = with pkgs; [
    minecraft
    osu-lazer
    runelite
  ];
  programs.anime-game-launcher.enable = true;
}
