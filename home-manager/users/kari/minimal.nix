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
  # User config
  users.users.${user} = {
    isNormalUser = true;
    password = config.sops.secrets."kari-password".path;
    group = "${user}";
    extraGroups = optionalGroups [
      "adbusers"
      "audio"
      "i2c"
      "input"
      "jackaudio"
      "libvirtd"
      "podman"
      "rtkit"
      "sftp"
      "users"
      "vboxusers"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;
  services.getty.autologinUser = user;

  # Secrets
  sops = {
    secrets = {
      "kari-password" = {
        sopsFile = ../../secrets.yaml;
        neededForUsers = true;
      };
    };
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  # Allows access to flake inputs
  home-manager.extraSpecialArgs = {inherit inputs;};

  home-manager.users."${user}" = {
    imports =
      [
        ./config/direnv.nix
        ./config/fish.nix
        ./config/git.nix
        ./config/neovim.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths [../../hosts/${config.networking.hostName}];

    # Default apps
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    home.packages = with pkgs; [
      eza
      htop
      kexec-tools
      lshw
      rsync
      tmux
      wget
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "23.05";
  };
}
