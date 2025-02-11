{ pkgs, ... }: {
  programs.lazygit = {
    enable = true;
    settings.git.paging = {
      colorArg = "always";
      pager = "${pkgs.delta}/bin/delta --dark --paging=never";
      useConfig = false;
    };
  };
}
