{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    defaultProfiles = [ "high-quality" ];
    config = {
      hwdec = "auto";
      volume = 50;
      ytdl-format = "bestvideo+bestaudio/best";
      osc = false;
      osd-font-size = 30;
      autofit = "30%x30%";
    };
    scripts = with pkgs.mpvScripts; [ sponsorblock thumbnail ];
    # Autogenerate decodes the whole file in software at startup; drops frames on sshfs media
    scriptOpts.mpv_thumbnail_script.autogenerate = false;
    bindings = {
      "l" = "seek 5";
      "h" = "seek -5";
      "j" = "seek -60";
      "k" = "seek 60";
    };
  };
}
