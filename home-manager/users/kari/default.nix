# https://github.com/hyper-dot/Arch-Hyprland
{
  self,
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
in {
  # This configuration extends the minimal-gui version
  imports = [
    ./minimal-gui.nix
  ];

  # Mount drives
  fileSystems = lib.mkIf (config.networking.hostName == "torque") {
    "/mnt/win" = {
      device = "/dev/disk/by-uuid/74D4CED9D4CE9CAC";
      fsType = "ntfs-3g";
      options = ["rw"];
    };
    "/mnt/sftp" = {
      device = "sftp@192.168.1.8:/";
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
    "d /home/${user}/Pictures 755 ${user} ${user} -"
    "d /home/${user}/Pictures/Screenshots 755 ${user} ${user} -"
    "d /home/${user}/Workspace 755 ${user} ${user} -"
  ];

  # Secrets
  sops = {
    secrets = {
      "wireguard/dinar".sopsFile = ../../secrets.yaml;
    };
    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };

  # Set initial password
  users.users.${user} = {
    initialPassword = "${user}";
  };

  # Wireguard
  networking.wg-quick.interfaces = {
    "wg0" = {
      autostart = false;
      configFile = config.sops.secrets."wireguard/dinar".path;
    };
  };

  # Misc
  programs.anime-game-launcher.enable = true;

  # Home-manager config
  home-manager.users."${user}" = rec {
    # Default apps
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
      #### SELF
      self.packages.${system}.ping-sweep
      self.packages.${system}.print-quote

      #### GUI
      brave
      czkawka
      discord
      element-desktop
      ferdium
      gimp-with-plugins
      libreoffice-qt
      #obsidian
      plexamp
      qemu
      rpi-imager
      sublime-merge
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
      ventoy

      # Lang
      rustc
      cargo
      rustfmt
      gcc

      # System Utilities
      nix-tree
      pciutils

      # Networking
      iputils
      nmap
      sshfs
      webcat
      wireguard-go
      wireguard-tools
      dhcpdump

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
