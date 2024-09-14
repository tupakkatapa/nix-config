{ lib
, pkgs
, ...
}: {
  boot = {
    kernelParams = [
      "boot.shell_on_fail"

      "mitigations=off"
      "l1tf=off"
      "mds=off"
      "no_stf_barrier"
      "noibpb"
      "noibrs"
      "nopti"
      "nospec_store_bypass_disable"
      "nospectre_v1"
      "nospectre_v2"
      "tsx=on"
      "tsx_async_abort=off"
    ];
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    tmp.tmpfsSize = "80%"; # default is 50%
  };

  environment.systemPackages = with pkgs; [
    bind
    btrfs-progs
    file
    fuse-overlayfs
    kexec-tools
    pciutils
    tmux
    vim
    wget
    lm_sensors
    lshw
  ];

  # Set the console keymap and font
  console.keyMap = "fi";
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-c24n.psf.gz";

  # Timezone, system version and locale
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };
  time.hardwareClockInLocalTime = true;

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Reset the user and group files on system activation
  users.mutableUsers = false;

  # Reboots hanged system
  systemd.watchdog.device = "/dev/watchdog";
  systemd.watchdog.runtimeTime = "30s";

  # Avoid locking up in low memory situations
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
  };

  # Zram swap
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.memoryPercent = 100;

  # Public key
  services.openssh.hostKeys = lib.mkDefault [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Sudo
  security = {
    sudo.enable = true;
    polkit.enable = true;
  };
}
