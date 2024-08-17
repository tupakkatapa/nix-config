{ pkgs, ... }:
let
  user = "core";
in
{
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torgue"
    ];
    shell = pkgs.fish;
  };
  users.groups."${user}" = { };
  environment.shells = [ pkgs.fish ];
  programs.fish = {
    enable = true;
    shellAbbrs = {
      q = "exit";
      c = "clear";
      ka = "pkill";

      # Powerstate
      bios = "systemctl reboot --firmware-setup";
      rbt = "reboot";
      sdn = "shutdown -h now";

      # Removed home directory once
      rm = "mv -it /tmp";
      remove = "rm";

      # Changing 'ls' to 'eza'
      ls = "eza -agl --color=always --group-directories-first";
      tree = "eza --git-ignore -T";

      # Rsync
      rcp = "rsync -PaL";
      rmv = "rsync -PaL --remove-source-files";

      # Adding flags
      df = "df -h";
      du = "du -h";
      mv = "mv -i";
      cp = "cp -ia";

      free = "free -h";
      grep = "grep --color=auto";
      jctl = "journalctl -p 3 -xb";

      # Nix
      nfc = "nix flake check --impure";
      gc = "nix-collect-garbage -d";

      # Misc
      vim = "nvim";
      lsd = "sudo du -Lhc --max-depth=0 *";
      port = "shuf -i 1024-65535 -n 1";
    };
  };

  # Install some packages
  environment.systemPackages = with pkgs; [
    refind
    vim
    eza
    lshw

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
}
