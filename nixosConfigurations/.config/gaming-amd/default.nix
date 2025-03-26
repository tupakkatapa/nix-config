{ pkgs
, ...
}: {
  # High quality games
  environment.systemPackages = with pkgs; [
    # runelite
    osu-lazer
    discord
  ];
  # programs.anime-game-launcher.enable = true;

  # Steam and gaming settings
  programs.gamescope.enable = true;
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode = {
    enable = true;
    settings = {
      general = { renice = 10; };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };
}
