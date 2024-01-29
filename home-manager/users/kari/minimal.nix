{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
  optionalGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in {
  # Secrets
  sops.secrets = {
    # echo "password" | mkpasswd -s
    kari-password = {
      sopsFile = ../../secrets.yaml;
      neededForUsers = true;
    };
  };
  # User config
  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    hashedPasswordFile = config.sops.secrets.kari-password.path;
    extraGroups = optionalGroups [
      "adbusers"
      "audio"
      "i2c"
      "input"
      "jackaudio"
      "libvirtd"
      "podman"
      "rtkit"
      "users"
      "vboxusers"
      "video"
      "wheel"
      "cups"
      "sshd"
      # Homelab groups
      "acme"
      "caddy"
      "jackett"
      "lanraragi"
      "photoprism"
      "plex"
      "radarr"
      "sftp"
      "transmission"
      "vaultwarden"
    ];
    openssh.authorizedKeys.keys = [
      # kari@torque
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"

      # kari@phone
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzhUITs3FB3ND6KMOjBwT04FD0jN+fuY8TIpO3U0Imdkhr++NgkHH8C8tXkKS+XJOUx6kHt9/DkLLmRJLe3qTwwarElgR1bVVIlOHx3Z1AY88b5CjcQV0ZruvZgasKKTfMx3TN5Zl3OBgGckHgAGozM8dZqUEMTE/U/hR/jatCaCEADgBCLM3rM2hCIcjTJ+Rk1rPBjOZzTdNogYWr9puyWu8kTaS/1gALI1bcJ235yKCrAr/fmzZDfBrPM9A9Y8B09rtOEE53GmpEXNyYsllOFA6nurSIIBxQNrUnOoKbCIgAjyttcA1aAxGIB+uZ1Sxnj4bZpHS1+GOqANY1ukeKkga02k2UVwtvMvCqLZHPQ9hUsg8H96V9PwvSUI68E3wEfoc7bV34Srh7TuBkDOcMv0kY5X1WmkgfS4n3CnPBIXoStw49RoMMoorhvazt9p2WIDlygmMWhESF0hYexRrpdVmvpRLjPlCR611PAhxIhn1aquvrr/WTKzWficSUbWbql6+ZYpwZUAaLb6qK35ohS//5gqH9MJCFJZTjfyWBSA2hAxA8hUGPxbGLOg53VDy03vxXCa21FnOWJVMv9bosBfGYPYyBhxTqmN9PJQ2msM1kb2u17E+ZHPt6JZbD4uDweOoPXWF0Bq4JNeA9LYdMgeoQ5hZt3hKuKao9MOF6zw== kari@phone"

      # kari@maliwan
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxmP58tAQ7oN1OT4nZ/pZtrb8vGvuh/l33lxiq3ngIU kari@maliwan"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh       755 ${user} ${user} -"
    "d /home/${user}/Workspace  755 ${user} ${user} -"
  ];

  # Allows access to flake inputs and custom packages
  home-manager.extraSpecialArgs = {inherit inputs pkgs;};

  home-manager.users."${user}" = {
    imports =
      [
        ./config/direnv.nix
        ./config/fish.nix
        ./config/git.nix
        ./config/neovim.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths
      [../../hosts/${config.networking.hostName}/default.nix];

    # Default apps
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    # Scripts and files
    home.sessionPath = ["$HOME/.local/bin"];
    home.file = let
      scriptDir = ./scripts;
      scriptFiles = builtins.readDir scriptDir;
      # Places scripts in '~/.local/bin/', create it with systemd.tmpfiles
    in
      builtins.mapAttrs (name: _: {
        executable = true;
        target = ".local/bin/${name}";
        source = "${scriptDir}/${name}";
      })
      scriptFiles;

    # Extra SSH config
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "192.168.1.*" = {
          extraOptions = {
            "StrictHostKeyChecking" = "no";
          };
        };
      };
      forwardAgent = true;
      addKeysToAgent = "yes";
    };
    services.ssh-agent.enable = true;

    home.packages = with pkgs; [
      ping-sweep
      fissh

      eza
      htop
      kexec-tools
      lkddb-filter
      lshw
      pciutils
      rsync
      tmux
      wget
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "23.11";
  };
}
