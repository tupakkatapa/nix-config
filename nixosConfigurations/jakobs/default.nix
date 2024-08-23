{ pkgs
, ...
}: {
  # Public key
  # age.rekey.hostPubkey = "";
  services.openssh.hostKeys = [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Use the Raspberry Pi 4 kernel
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

  # Connectivity
  networking.hostName = "jakobs";
  networking.firewall.enable = true;
  hardware.bluetooth.enable = true;
}
