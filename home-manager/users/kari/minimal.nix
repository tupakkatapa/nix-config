{ pkgs
, lib
, config
, inputs
, ...
}:
let
  user = "kari";
  optionalGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in
{
  users.users.${user} = {
    isNormalUser = true;
    uid = 1000;
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

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user}.gid = 1000;
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  # Allows access to flake inputs and custom packages
  home-manager.extraSpecialArgs = { inherit inputs pkgs; };

  # Move existing files rather than exiting with an error
  home-manager.backupFileExtension = "bak";

  home-manager.users."${user}" = {
    imports =
      [
        ./.config/direnv.nix
        ./.config/fish.nix
        ./.config/neovim.nix
        ./.config/yazi.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths
        [ ../../hosts/${config.networking.hostName}/default.nix ];

    # Git
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      extraConfig = {
        safe.directory = [ "*" ];
        http = {
          # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
          postBuffer = "524288000";
        };
      };
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
      in
      builtins.mapAttrs (name: _: makeScript name) scriptFiles;

    # Default apps
    home.sessionVariables = {
      #   BROWSER = lib.mkDefault "none";
      #   FILEMANAGER = lib.mkDefault "none";
      #   FONT = lib.mkDefault "none";
      #   TERMINAL = lib.mkDefault "none";
      THEME = lib.mkDefault "gruvbox-dark-medium";
    };

    home.packages = with pkgs; [
      tupakkatapa-utils
      ping-sweep

      ffmpeg
      yt-dlp
      eza

      # Rust  
      cargo
      evcxr
      rustc
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "24.05";
  };
}
