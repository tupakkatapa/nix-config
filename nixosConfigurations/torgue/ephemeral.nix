_:
let
  user = "kari";
  appData = "/mnt/860/appdata";
in
{
  # This file is for when I have the hardware and a stable netboot server to go ephemeral

  /*
    Persistent file memo

    yubikey:
    ~/.config/Yubico/u2f_keys

    ssh:
    ~/.ssh/id_ed25519
    /etc/ssh/ssh_host_ed25519_key

    other:
    ~/.config/guitarix/banks
  */

  # Enable NIC driver for stage-1
  boot.kernelPatches = [
    {
      name = "kernel nic config (torgue)";
      patch = null;
      extraConfig = ''
        IGB y
        ETHERNET y
        NET_VENDOR_INTEL y
      '';
    }
  ];

  # Extra SSH/SFTP settings
  services.openssh.hostKeys = [
    {
      path = "/mnt/860/secrets/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  # Mount drives
  fileSystems."/mnt/860" = {
    device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
    fsType = "btrfs";
    # options = ["subvolid=420"];
    neededForBoot = true;
  };
  fileSystems."/mnt/boot" = {
    device = "/dev/disk/by-uuid/AD1A-1390";
    fsType = "auto";
  };
  fileSystems."/mnt/870" = {
    device = "/dev/disk/by-uuid/74D4CED9D4CE9CAC";
    fsType = "ntfs-3g";
    options = [ "rw" ];
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /mnt/sftp                   755 root root -"
    "d /mnt/boot                   755 root root -"
    "d /mnt/860                    755 root root -"
    "d /mnt/860/games              755 root root -"
    "d /mnt/860/secrets            755 root root -"
    "d /mnt/860/nix-config         755 root root -"
    "d ${appData}                  777 root root -"
    "d ${appData}/firefox          755 ${user} ${user} -"
    "d /mnt/870                    755 root root -"
  ];

  # Bind firefox directory to preserve cookies and such
  fileSystems."/home/${user}/.mozilla" = {
    device = "${appData}/firefox";
    options = [ "bind" "mode=755" ];
  };
}
