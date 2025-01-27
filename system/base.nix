{ lib
, pkgs
, ...
}: {
  # Use the latest kernel
  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Set the console keymap
  console.keyMap = "fi";

  # Localization
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "fi_FI.UTF-8";
  };

  # Reset the user and group files on system activation
  users.mutableUsers = false;

  # Only generate an ed25519 key
  services.openssh.hostKeys = lib.mkDefault [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Essential packages
  environment.systemPackages = with pkgs; [
    btrfs-progs
    htop
    kexec-tools
    rsync
    tmux
    vim
    wget
  ];
}
