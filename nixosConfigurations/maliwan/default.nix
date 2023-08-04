{pkgs, ...}: {
  # Timezone and system version
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Connectivity
  networking = {
    networkmanager.enable = true;
    hostName = "maliwan";
    firewall.enable = false;
  };
  hardware.bluetooth.enable = true;

  services.openssh = {
    enable = true;
    allowSFTP = false;
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Audio settings
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
