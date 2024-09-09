{ pkgs, lib, ... }: {
  networking.hostName = "gearbox";
  console.keyMap = "fi";

  boot.kernelParams = [
    # Initiates a an interactive shell at Stage 1
    # "boot.debug1"

    # Same as debug1, but waits until kernel modules are loaded
    # "boot.debug1devices"

    # Same as debug1, but waits until 'neededForBoot' filesystems are mounted
    # "boot.debug1mounts"
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
    displayManager.lightdm.enable = true;
  };
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "core";
    };
    defaultSession = "xfce";
  };

  # Packages
  environment.systemPackages = with pkgs; [
    librewolf
  ];
}

