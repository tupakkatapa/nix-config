_: {
  programs.imv = {
    enable = true;
    settings.binds = {
      q = "quit";
      x = "close";
      f = "fullscreen";
      c = "center";
      r = "reset";

      # Navigating
      gg = "goto 0";
      "<Shift+G>" = "goto -1";
      "<Ctrl+r>" = "rotate by 90";

      # Panning
      J = "pan 0 -50";
      K = "pan 0 50";
      H = "pan 50 0";
      L = "pan -50 0";

      # Zooming
      j = "zoom -1";
      k = "zoom 1";
      l = "next";
      h = "prev";

      # Gif playback
      "<space>" = "toggle_playing";
    };
  };
}
