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
      ]
      ++ optionalGroups [
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
        ./config/librewolf.nix
        ./config/vscode.nix

        # CLI Apps
        ./config/fish.nix
        ./config/neovim.nix
        ./config/git.nix
        ./config/direnv.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths [../../hosts/${config.networking.hostName}];

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

    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "application/msword" = ["writer.desktop"];
      "application/vnd.oasis.opendocument.spreadsheet" = ["impress.desktop"];
      "application/vnd.oasis.opendocument.text" = ["writer.desktop"];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = ["writer.desktop"];
      "text/csv" = ["impress.desktop"];
    };

    home.packages = with pkgs; [
      # GUI Apps
      discord
      ferdium
      plex-media-player
      plexamp
      qemu
      mpv
      rpi-imager
      ventoy
      obsidian
      sublime-merge
      libreoffice-qt

      # Music stuff
      ardour
      guitarix
      qjackctl

      # High quality games
      osu-lazer
      runelite

      # Android dev
      android-tools

      # CLI Apps
      bat
      zip
      unzip
      p7zip
      jq
      exa
      gnupg
      htop
      iputils
      kexec-tools
      lshw
      neofetch
      nix
      nix-tree
      ripgrep
      rsync
      ssh-to-age
      sshfs
      tmux
      vim
      wget
      wireguard-go
      wireguard-tools
      yt-dlp
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "23.05";
  };
}
