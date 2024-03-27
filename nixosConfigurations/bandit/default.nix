{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  user = "core";
in {
  networking.hostName = "bandit";
  console.keyMap = "fi";

  # Autologin
  services.getty.autologinUser = user;

  # Enable SSH
  services.openssh.enable = true;

  # User config
  users.users."${user}" = {
    isNormalUser = true;
    group = user;
    extraGroups = [
      "audio"
      "users"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups."${user}" = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  # Install some packages
  environment.systemPackages = with pkgs; [
    lkddb-filter
    refind
    vim
    eza

    # https://github.com/coreboot/coreboot/blob/main/util/liveiso/nixos/common.nix
    acpica-tools
    btrfs-progs
    bzip2
    ccrypt
    chipsec
    coreboot-utils
    cryptsetup
    curl
    ddrescue
    devmem2
    dmidecode
    dosfstools
    e2fsprogs
    efibootmgr
    efivar
    exfat
    f2fs-tools
    fuse
    fuse3
    fwts
    gptfdisk
    gitAndTools.gitFull
    gitAndTools.tig
    gzip
    hdparm
    hexdump
    htop
    i2c-tools
    intel-gpu-tools
    inxi
    iotools
    jfsutils
    jq
    lm_sensors
    mdadm
    minicom
    mkpasswd
    ms-sys
    msr-tools
    mtdutils
    neovim
    nixos-install-tools
    ntfsprogs
    nvme-cli
    openssl
    p7zip
    pacman
    parted
    pcimem
    pciutils
    phoronix-test-suite
    powertop
    psmisc
    python3Full
    rsync
    screen
    sdparm
    smartmontools
    socat
    sshfs-fuse
    testdisk
    tmate
    tmux
    uefitool
    uefitoolPackages.old-engine
    unzip
    upterm
    usbutils
    wget
    zfs
    zip
    zstd
  ];

  # Allow passwordless sudo from wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
    execWheelOnly = true;
  };
}
