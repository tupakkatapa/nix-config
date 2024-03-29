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
  # This configuration extends the minimal-gui version
  imports = [./minimal-gui.nix];

  # Mount drives
  fileSystems = lib.mkIf (config.networking.hostName == "torque") {
    "/mnt/win" = {
      device = "/dev/disk/by-uuid/74D4CED9D4CE9CAC";
      fsType = "ntfs-3g";
      options = ["rw"];
    };
  };

  # Mount SFTP and bind home directories
  services.sftpClient = let
    identifyFile = "/home/${user}/.ssh/id_ed25519";
    sftpPrefix = "sftp@192.168.1.8:";
  in {
    enable = true;
    mounts =
      [
        {
          inherit identifyFile;
          what = "${sftpPrefix}/";
          where = "/mnt/sftp";
        }
      ]
      ++ (map (dir: {
        inherit identifyFile;
        what = "${sftpPrefix}/home/${dir}";
        where = "/home/${user}/${dir}";
      }) ["Downloads" "Pictures" "Workspace" "Documents"]);
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
    xdg.configFile."mimeapps.list".force = true;

    home.packages = with pkgs; [
      #### SELF
      print-banner
      monitor-adjust

      #### GUI
      czkawka
      ferdium
      gimp-with-plugins
      libreoffice-qt
      #obsidian
      plexamp
      qemu
      rpi-imager
      sublime-merge
      video-trimmer
      chromium
      palemoon-bin

      #### High Quality Games
      osu-lazer
      runelite

      #### CLI
      android-tools
      gnupg
      grub2
      parallel
      ssh-to-age
      yt-dlp
      ventoy

      #### Lang
      rustc
      cargo
      rustfmt
      gcc

      #### System Utilities
      nix-tree

      #### Networking
      iputils
      nmap
      webcat
      wireguard-go
      wireguard-tools
      dhcpdump

      #### Archive
      unrar
    ];
  };
}
