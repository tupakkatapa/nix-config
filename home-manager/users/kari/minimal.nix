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

  # Secrets
  age.secrets = {
    "wg-dinar".rekeyFile = ./secrets/wg-dinar.age;
    "ed25519-sk" = {
      rekeyFile = ./secrets/ed25519-sk.age;
      path = "/home/${user}/.ssh/id_ed25519_sk";
      mode = "600";
      owner = user;
      group = user;
    };
  };

  # Wireguard
  networking.wg-quick.interfaces."wg0" = {
    autostart = true;
    configFile = config.age.secrets.wg-dinar.path;
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
      # kari@phone
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
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
        ./.config/yazi.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths
        [ ../../hosts/${config.networking.hostName}/default.nix ];

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
        "192.168.1.171" = {
          user = "core";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "vladof" = {
          hostname = "192.168.1.8";
          extraOptions."StrictHostKeyChecking" = "no";
        };
      };
      forwardAgent = true;
      addKeysToAgent = "yes";
    };
    services.ssh-agent.enable = true;

    # Default apps
    home.sessionVariables = {
      THEME = "gruvbox-dark-medium";
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
