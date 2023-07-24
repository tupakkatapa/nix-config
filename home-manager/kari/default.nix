{ pkgs, config, inputs, lib, ... }: with lib;
{
  users.users.kari = {
    isNormalUser = true;
    password = "random123";
    #passwordFile = config.sops.secrets.kari-password.path;
    group = "kari";
    extraGroups = [ "wheel" "users" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque" ];
    shell = pkgs.fish;
  };
  users.groups.kari = { };
  environment.shells = [ pkgs.fish ];

  sops.secrets.kari-password = {
    sopsFile = ../../nixosConfigurations/torque/secrets.yaml;
    neededForUsers = true;
  };
  security.pam.services = { swaylock = { }; };

  programs = {
    neovim = {
      enable = true;
    };
    fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    plexamp
    plex-media-player
    guitarix
    qjackctl
    ferdium
    discord
  ];

  # Home-manager
  home-manager.users.kari = {

    imports = [
      ./config/fish.nix
      ./config/waybar.nix
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.default;
      extraConfig = (import ./config/hyprland.nix { inherit config; });
    };

    home.packages = with pkgs; [
      gnupg
      rsync
    ];

    programs = {
      exa.enable = true;
      tmux.enable = true;
      htop.enable = true;
      vim.enable = true;
      git.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
      };
      home-manager.enable = true;
      alacritty.enable = true;
      #librewolf.enable = true;
    };

    home.stateVersion = "23.05";
  };
}
