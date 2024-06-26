{ pkgs
, config
, inputs
, lib
, ...
}:
let
  user = "kari";
  optionalGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in
{
  # Mount drives
  fileSystems = lib.mkIf (config.networking.hostName == "torgue") {
    "/mnt/win" = {
      device = "/dev/disk/by-uuid/74D4CED9D4CE9CAC";
      fsType = "ntfs-3g";
      options = [ "rw" ];
    };
  };

  # Mount SFTP and bind home directories
  services.sftpClient =
    let
      sftpPrefix = "sftp@192.168.1.8:";
    in
    lib.mkIf (config.networking.hostName != "vladof") {
      enable = true;
      defaultIdentityFile = "/home/${user}/.ssh/id_ed25519";
      mounts =
        [
          {
            what = "${sftpPrefix}/";
            where = "/mnt/sftp";
          }
          {
            what = "${sftpPrefix}/docs";
            where = "/home/${user}/Documents";
          }
          {
            what = "${sftpPrefix}/media";
            where = "/home/${user}/Media";
          }
          {
            what = "${sftpPrefix}/code/workspace";
            where = "/home/${user}/Workspace";
          }
          {
            what = "${sftpPrefix}/dnld";
            where = "/home/${user}/Downloads";
          }
        ];
    };

  # Wireguard
  sops.secrets.wg-dinar = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };
  networking.wg-quick.interfaces."wg0" = {
    autostart = true;
    configFile = config.sops.secrets.wg-dinar.path;
  };

  # User config
  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    extraGroups = optionalGroups [
      "acme"
      "adbusers"
      "audio"
      "caddy"
      "cups"
      "disk"
      "i2c"
      "input"
      "jackaudio"
      "libvirtd"
      "podman"
      "rtkit"
      "sftp"
      "sshd"
      "users"
      "vboxusers"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      # kari@torgue
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torgue"

      # kari@phone
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzhUITs3FB3ND6KMOjBwT04FD0jN+fuY8TIpO3U0Imdkhr++NgkHH8C8tXkKS+XJOUx6kHt9/DkLLmRJLe3qTwwarElgR1bVVIlOHx3Z1AY88b5CjcQV0ZruvZgasKKTfMx3TN5Zl3OBgGckHgAGozM8dZqUEMTE/U/hR/jatCaCEADgBCLM3rM2hCIcjTJ+Rk1rPBjOZzTdNogYWr9puyWu8kTaS/1gALI1bcJ235yKCrAr/fmzZDfBrPM9A9Y8B09rtOEE53GmpEXNyYsllOFA6nurSIIBxQNrUnOoKbCIgAjyttcA1aAxGIB+uZ1Sxnj4bZpHS1+GOqANY1ukeKkga02k2UVwtvMvCqLZHPQ9hUsg8H96V9PwvSUI68E3wEfoc7bV34Srh7TuBkDOcMv0kY5X1WmkgfS4n3CnPBIXoStw49RoMMoorhvazt9p2WIDlygmMWhESF0hYexRrpdVmvpRLjPlCR611PAhxIhn1aquvrr/WTKzWficSUbWbql6+ZYpwZUAaLb6qK35ohS//5gqH9MJCFJZTjfyWBSA2hAxA8hUGPxbGLOg53VDy03vxXCa21FnOWJVMv9bosBfGYPYyBhxTqmN9PJQ2msM1kb2u17E+ZHPt6JZbD4uDweOoPXWF0Bq4JNeA9LYdMgeoQ5hZt3hKuKao9MOF6zw== kari@phone"

      # kari@maliwan
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxmP58tAQ7oN1OT4nZ/pZtrb8vGvuh/l33lxiq3ngIU kari@maliwan"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = { };
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh       755 ${user} ${user} -"
    "d /home/${user}/Workspace  755 ${user} ${user} -"
    "d /home/${user}/Media      755 ${user} ${user} -"
  ];

  # Allows access to flake inputs and custom packages
  home-manager.extraSpecialArgs = { inherit inputs pkgs; };

  # Move existing files rather than exiting with an error
  home-manager.backupFileExtension = "bak";

  home-manager.users."${user}" = {
    imports =
      [
        ./.config/direnv.nix
        ./.config/fish.nix
        ./.config/git.nix
        ./.config/neovim.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths
        [ ../../hosts/${config.networking.hostName}/default.nix ];

    # Default apps
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    # Scripts and files
    home.sessionPath = [ "$HOME/.local/bin" ];
    home.file =
      let
        scriptDir = ./scripts;
        scriptFiles = builtins.readDir scriptDir;
        makeScript = name: {
          executable = true;
          target = ".local/bin/${name}";
          source = "${scriptDir}/${name}";
        };
        staticFiles = {
          ".config/jack/focusrite_guitarix_v2.xml".source = ./.config/focusrite_guitarix_v2.xml;
          ".config/jack/focusrite_guitarix_ardour_v2.xml".source = ./.config/focusrite_guitarix_ardour_v2.xml;
        };
      in
      staticFiles // builtins.mapAttrs (name: _: makeScript name) scriptFiles;

    # Extra SSH config
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "192.168.1.*".extraOptions."StrictHostKeyChecking" = "no";
        "192.168.100.*" = {
          user = "core";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "vladof".hostname = "192.168.1.8";
      };
      forwardAgent = true;
      addKeysToAgent = "yes";
    };
    services.ssh-agent.enable = true;

    # Terminal file manager
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
    };

    home.packages = with pkgs; [
      tupakkatapa-utils
      lkddb-filter
      ping-sweep
      pinit

      ffmpeg
      kexec-tools
      lshw
      refind
      vim
      didyoumean
      translate-shell
      iputils
      dhcpdump
      webcat
      unrar
      gnupg
      ssh-to-age
      parallel
      yt-dlp
      kalker

      # replacements
      bat
      eza
      fd
      ripgrep

      # https://github.com/coreboot/coreboot/blob/main/util/liveiso/nixos/common.nix
      acpica-tools
      btrfs-progs
      bzip2
      ccrypt
      # chipsec
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
      # intel-gpu-tools
      inxi
      # iotools
      jfsutils
      jq
      lm_sensors
      mdadm
      minicom
      mkpasswd
      ms-sys
      msr-tools
      mtdutils
      # neovim
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
      # uefitoolPackages.old-engine
      unzip
      upterm
      usbutils
      wget
      zfs
      zip
      zstd
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "23.11";
  };
}
