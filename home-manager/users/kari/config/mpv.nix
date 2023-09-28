# https://github.com/Tsubajashi/mpv-settings
{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    config = {
      # Player
      gpu-api = "vulkan";
      input-ipc-server = "/tmp/mpvsocket";
      hr-seek-framedrop = "no";
      no-resume-playback = true;
      border = "no";
      msg-color = "yes";
      msg-module = "yes";
      autofit = "85%x85%";
      cursor-autohide = 100;

      # OSC
      osc = "yes";
      osd-bar = "yes";
      osd-font = "JetBrains Mono";
      osd-font-size = 30;
      osd-color = "#CCFFFFFF";
      osd-border-color = "#DD322640";
      osd-bar-align-y = -1;
      osd-border-size = 2;
      osd-bar-h = 1;
      osd-bar-w = 60;

      # Audio
      volume = 50;
      volume-max = 200;
      audio-stream-silence = true;
      audio-file-auto = "fuzzy";
      audio-pitch-correction = "yes";
      alang = "jpn,jp,eng,en,enUS,en-US";
      slang = "eng,en";

      # Video profiles
      profile = "gpu-hq";
      hwdec = "auto-copy-safe";
      vo = "gpu-next";

      dither-depth = "auto";

      deband = "yes";
      deband-iterations = 4;
      deband-threshold = 35;
      deband-range = 16;
      deband-grain = 4;

      scale = "ewa_lanczos";
      scale-blur = 0.981251;

      dscale = "catmull_rom";
      correct-downscaling = "yes";
      linear-downscaling = "no";

      cscale = "lanczos";
      sigmoid-upscaling = "yes";

      scale-antiring = 0.7;
      dscale-antiring = 0.7;
      cscale-antiring = 0.7;

      video-sync = "display-resample";
      interpolation = "yes";
      tscale = "sphinx";
      tscale-blur = 0.6991556596428412;
      tscale-radius = 1.05;
      tscale-clamp = 0.0;

      tone-mapping = "bt.2446a";
      tone-mapping-mode = "luma";

      target-colorspace-hint = "yes";

      # Playback
      deinterlace = "no";
    };
  };
}
