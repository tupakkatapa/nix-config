{ lib
, pkgs
, ...
}: {
  # Use LTS kernel
  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

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

  # Only swap to avoid OOM
  boot.kernel.sysctl."vm.swappiness" = 0;

  # Compressed RAM swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Early OOM killer
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  # Limit journal size
  services.journald.extraConfig = "SystemMaxUse=128M";

  # Create /bin/bash symlink
  system.activationScripts.binbash = ''
    mkdir -p /bin
    ln -sf ${pkgs.bash}/bin/bash /bin/bash
  '';

  # Essential packages
  environment.systemPackages = with pkgs; [
    btrfs-progs
    htop
    kexec-tools
    lshw
    rsync
    tmux
    vim
    wget
    curl
    pciutils
    lsof
    dig
    jq
    jc
  ];
}
