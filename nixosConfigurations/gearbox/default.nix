{ pkgs, lib, ... }: {
  networking.hostName = "gearbox";
  console.keyMap = "fi";

  # Enable NIC driver for stage-1
  boot.kernelPatches = [
    {
      name = "kernel nic config (torgue)";
      patch = null;
      extraConfig = ''
        E1000 y
        ETHERNET y
        NET_VENDOR_INTEL y
      '';
    }
  ];

  # Autologin
  services.getty.autologinUser = "core";

  # Enable SSH
  services.openssh.enable = true;

  # Allow passwordless sudo from wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
    execWheelOnly = true;
  };

  # Xfce
  services.xserver = {
    enable = true;
    xkb.layout = "fi";
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager = {
      autoLogin = {
        enable = true;
        user = "core";
      };
      lightdm.enable = true;
      defaultSession = "xfce";
    };
  };

  # Wine
  environment.systemPackages = with pkgs; [
    wineWowPackages.staging
    librewolf
  ];
}

