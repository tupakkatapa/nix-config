{ pkgs, lib, ... }: {
  programs.imv = {
    enable = true;
    settings.binds = {
      q = "quit";
      "<Left>" = "prev";
      "<bracketleft>" = "prev";
      "<Right>" = "next";
      "<bracketright>" = "next";
      gg = "goto 0";
      "<Shift+G>" = "goto -1";

      # Panning
      J = "pan 0 -50";
      K = "pan 0 50";
      H = "pan 50 0";
      L = "pan -50 0";

      # Zooming
      j = "zoom -1";
      k = "zoom 1";
      "<minus>" = "zoom -1";
      "<plus>" = "zoom 1";
      l = "next";
      h = "prev";

      "<Up>" = "zoom 1";
      "<Shift+plus>" = "zoom 1";
      "<Down>" = "zoom -1";
      i = "exec ${lib.getExe pkgs.libnotify} -t 800 -u low -i image-x-generic \$imv_current_file";

      # Other commands
      x = "close";
      f = "fullscreen";
      d = "overlay";
      p = "exec echo \$imv_current_file";
      c = "center";
      s = "scaling next";
      "<Shift+S>" = "upscaling next";
      a = "zoom actual";
      r = "reset";

      # Gif playback
      "<period>" = "next_frame";
      "<space>" = "toggle_playing";
    };
  };
}
