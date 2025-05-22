{ pkgs, ... }: {
  # High quality games
  environment.systemPackages = with pkgs; [
    prismlauncher
    osu-lazer
    runelite
  ];
}
