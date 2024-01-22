{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    defaultProfiles = ["gpu-hq"];
    config = {
      gpu-api = "vulkan";
      gpu-context = "waylandvk";
      vo = "gpu-next";
      hwdec = "auto-copy-safe";
      volume = 50;
      ytdl-format = "bestvideo+bestaudio/best";
      osc = false;
      osd-font-size = 30;
      autofit = "30%x30%";
    };
    scripts = with pkgs.mpvScripts; [sponsorblock thumbnail];
    bindings = {
      "l" = "seek 5";
      "h" = "seek -5";
      "j" = "seek -60";
      "k" = "seek 60";
    };
  };
}
