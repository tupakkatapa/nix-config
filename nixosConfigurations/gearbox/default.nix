{ pkgs, lib, ... }: {
  networking.hostName = "gearbox";
  console.keyMap = "fi";

  # Enable NIC driver for stage-1
  boot.kernelPatches = [
    {
      name = "enable e1000 for PC";
      patch = null;
      extraConfig = ''
        ETHERNET y
        NET_VENDOR_INTEL y
        E1000 y
      '';
    }
    {
      name = "enable r8169 for laptop";
      patch = null;
      extraConfig = ''
        ETHERNET y
        NET_VENDOR_REALTEK y
        R8169 y
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

