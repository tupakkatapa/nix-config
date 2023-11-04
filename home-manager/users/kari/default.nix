# https://github.com/hyper-dot/Arch-Hyprland
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
in {
  # This configuration extends the minimal version
  imports = [
    ./minimal.nix
  ];

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
        "IdentityFile=/home/kari/.ssh/id_ed25519"
        "ServerAliveInterval=15"
        "_netdev"
        "allow_other"
        "reconnect"
        "x-systemd.automount"
      ];
    };
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/${user}/.local/bin 755 ${user} ${user} -"
    "d /home/${user}/.ssh 755 ${user} ${user} -"
    "d /home/${user}/Pictures/Screenshots 755 ${user} ${user} -"
    "d /home/${user}/Workspace 755 ${user} ${user} -"
  ];

  # Secrets
  sops = {
    secrets = {
      "wireguard/dinar".sopsFile = ../../secrets.yaml;
      "kari-password" = {
        sopsFile = ../../secrets.yaml;
        neededForUsers = true;
      };
    };
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  # Set password
  users.users.${user} = {
    password = config.sops.secrets."kari-password".path;
  };

  # Wireguard
  networking.wg-quick.interfaces = {
    "wg0" = {
      autostart = false;
      configFile = config.sops.secrets."wireguard/dinar".path;
    };
  };

  programs.anime-game-launcher.enable = true;

  # Home-manager config
  home-manager.users."${user}" = rec {
    imports = [
      ./config/alacritty.nix
      ./config/firefox.nix
      ./config/mpv.nix
    ];

    # Default apps
    home.sessionVariables = {
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
        };
        "192.168.1.*" = {
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
    in
      # Places scripts in '~/.local/bin/', create it with systemd.tmpfiles
      builtins.mapAttrs (name: _: {
        executable = true;
        target = ".local/bin/${name}";
        source = "${scriptDir}/${name}";
      })
      scriptFiles;

    home.packages = with pkgs; [
      #### GUI
      brave
      czkawka
      discord
      element-desktop
      ferdium
      gimp-with-plugins
      libreoffice-qt
      obsidian
      plexamp
      qemu
      rpi-imager
      sublime-merge
      ventoy
      video-trimmer

      # High Quality Games
      osu-lazer
      runelite

      #### CLI
      android-tools
      ffmpeg
      gnupg
      grub2
      jq
      kalker
      parallel
      ssh-to-age
      yt-dlp

      # System Utilities
      neofetch
      nix-tree

      # Networking
      iputils
      nmap
      sshfs
      webcat
      wireguard-go
      wireguard-tools

      # Alternatives
      bat
      fd
      ripgrep

      # Archive
      p7zip
      unrar
      unzip
      zip
    ];
  };
}
