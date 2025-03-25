_:
{
  programs.foot = {
    enable = true;

    settings = {
      main = {
        term = "xterm-256color";
        dpi-aware = "yes";
        pad = "20x20";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
