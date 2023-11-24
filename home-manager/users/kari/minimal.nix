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

  # Autologin if no password is set
  services.getty.autologinUser = let
    userCfg = config.users.users."${user}";
  in
    lib.mkIf (
      userCfg.password
      == null
      && userCfg.initialPassword == null
      && userCfg.hashedPasswordFile == null
      && userCfg.hashedPassword == null
      && userCfg.initialHashedPassword == null
    )
    user;

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
      ++ optionalPaths [../../hosts/${config.networking.hostName}/default.nix];

    # Default apps
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
      TERMINAL = lib.mkDefault "none";
      BROWSER = lib.mkDefault "none";
      FILEMANAGER = lib.mkDefault "none";
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
