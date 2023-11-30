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
      # kari@torque
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"

      # kari@android
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKk3kgeXBMsnpL0/uFLMYwBez1SXU92GyvyjAtmFZkSt kari@phone"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqcpV951HXpC4Fe8KY3VYKTkWIcwJ1KSXA6xub2gOKbsOzerCFf7AaAJluprpi5YuV9n84RZatjF9E7tk+wjCsgDbfqO9AFWtJtCmyFWfs1cMzmhhxRt8A8KkK56FpJLmLjxEbkeMd8EpLS4HmwWLk+hd5c+1Cz/KgLfIA6WeLt72jArBGjpKFFcW4tLTR+U0I/uW7+YyTIyF8UmINlAHXsOdTptcfHmKIiRek+ySYyGLId3GGtZ0k2Dgh1E3/sHpi3x1GSztXmmn1QFUOeSDe62TRW6Wg78jDXiTUl0HwlIFuvtQ26UTdteC83nHvf70GGh5jH14o1uWhWN0WaE046Sm7aZGOIZ1OX5bfVE6m+taPohF+4Pw1NMV76l6zpRz2X6tSbcG3NSL1Zfx7q/v97M05VsAxMger4mI0h25fdaZSFUh+cNKrRXG12tjr+DZHOCUI2UdSuNp1A8JcKh5k9hL/WR17ZcQDY1Siau1ea/pqzqU6GHFMRLM1w+84jcKOVKFLMSAxl7vbb5dP3OU9CDXWf/fkXl9b2oci/DKNHhZ7G2kLTq6+pE8rPs8A0o48yUkQkYeYoeqNRediAKvcBju4xtdbFidzctV7GgqkH1CL56LbakV8GqsxBH12MK0F36U8PV1xeDYkklVVjX/380OQJD3Yq/hrOV70rcYJMQ== kari@android"

      # kari@macbook
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZlujrZ4ng+IMfiFPKxpMEC5CAcuLN+Xo5zahtHYxy/ kari@macbook"

      # kari@maliwan
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/n5+r2xsdwwIqpnfSQwle9k2G1vTr5pKnIW7Gv4dM1 kari@maliwan"
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
