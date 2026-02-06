{ pkgs, ... }: {
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
  };

  # Utilities
  environment.systemPackages = with pkgs; [
    alsa-utils
    qpwgraph
  ];

  # Make pipewire realtime-capable
  security.rtkit.enable = true;

  # PAM limits for realtime audio
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "99999";
    }
  ];

  # Real-time audio settings
  boot = {
    kernelModules = [ "snd-seq" "snd-rawmidi" ];
    kernelParams = [ "threadirqs" ];
  };
  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';
  powerManagement.cpuFreqGovernor = "performance";
}
