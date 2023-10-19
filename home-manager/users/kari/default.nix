# https://github.com/hyper-dot/Arch-Hyprland
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
  optionalGroups = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in {
  # User config, setting password manually
  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    extraGroups =
      [
        "audio"
        "video"
        "wheel"
        "users"
      ]
      ++ optionalGroups [
        "vboxusers"
        "rtkit"
        "input"
        "jackaudio"
        "users"
        "i2c"
        "podman"
        "libvirtd"
        "adbusers"
      ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  # Mount drives
  fileSystems = lib.mkIf (config.networking.hostName == "torque") {
    "/mnt/3TB" = {
      device = "/dev/disk/by-uuid/60c4a67d-166b-48d2-a1c2-e457850a87df";
      fsType = "ext4";
    };
    "/mnt/WIN" = {
      device = "/dev/disk/by-uuid/74D4CED9D4CE9CAC";
      fsType = "ntfs-3g";
      options = ["rw"];
    };
    "/mnt/SFTP" = {
      device = "sftp_user@vladof:/root/";
      fsType = "sshfs";
      options = [
        "allow_other"
        "_netdev"
        "x-systemd.automount"
        "reconnect"
        "ServerAliveInterval=15"
        "IdentityFile=/home/kari/.ssh/id_ed25519"
      ];
    };
  };

  # Allows access to flake inputs
  home-manager.extraSpecialArgs = {inherit inputs;};

  # Home-manager config
  home-manager.users."${user}" = rec {
    imports =
      [
        # GUI Apps
        ./config/alacritty.nix
        ./config/firefox.nix
        ./config/mpv.nix

        # CLI Apps
        ./config/fish.nix
        ./config/neovim.nix
        ./config/git.nix
        ./config/direnv.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths [../../hosts/${config.networking.hostName}];

    # Default apps
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
      BROWSER = "firefox";
      TERMINAL = "alacritty";
    };
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "application/msword" = ["writer.desktop"];
      "application/vnd.oasis.opendocument.spreadsheet" = ["impress.desktop"];
      "application/vnd.oasis.opendocument.text" = ["writer.desktop"];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = ["writer.desktop"];
      "text/csv" = ["impress.desktop"];
    };

    # Extra SSH config
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "ponkila" = {
          hostname = "192.168.100.10";
          user = "core";
        };
        "pxe-server" = {
          hostname = "192.168.1.169";
          user = "core";
          extraOptions = {
            "StrictHostKeyChecking" = "no";
          };
        };
      };
    };

    # Scripts and files
    home.sessionPath = ["$HOME/.local/bin"];
    home.file = let
      scriptDir = ./scripts;
      scriptFiles = builtins.readDir scriptDir;

      # Places scripts in '~/.local/bin/', create it with systemd.tmpfiles
      scriptAttrs =
        builtins.mapAttrs (name: _: {
          executable = true;
          target = ".local/bin/${name}";
          source = "${scriptDir}/${name}";
        })
        scriptFiles;

      # Qjackctl presets
      qjackctlPresets = {
        "focusrite_guitarix_v2.xml".source = ./config/qjackctl/focusrite_guitarix_v2.xml;
        "focusrite_guitarix_ardour_v2.xml".source = ./config/qjackctl/focusrite_guitarix_ardour_v2.xml;
      };
    in (scriptAttrs // qjackctlPresets);

    home.packages = with pkgs; [
      #### GUI
      czkawka
      discord
      ferdium
      libreoffice-qt
      obsidian
      plexamp
      qemu
      rpi-imager
      sublime-merge
      ventoy
      gimp-with-plugins
      video-trimmer
      picard
      brave

      # Music Production
      qjackctl
      tuxguitar

      # High Quality Games
      osu-lazer
      runelite

      #### CLI
      android-tools
      ffmpeg
      gnupg
      jq
      parallel
      ssh-to-age
      tmux
      wget
      yt-dlp

      # System Utilities
      htop
      kexec-tools
      lshw
      neofetch
      nix-tree

      # Networking
      iputils
      nmap
      rsync
      sshfs
      webcat
      wireguard-go
      wireguard-tools

      # Alternatives
      bat
      eza
      fd
      ripgrep

      # Archive
      p7zip
      unrar
      unzip
      zip
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "23.05";
  };
}
