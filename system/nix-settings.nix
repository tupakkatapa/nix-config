{
  inputs,
  outputs,
  config,
  lib,
  ...
}: {
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://ezkea.cachix.org"
        "http://torque.coditon.com:5000"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
        "torque.coditon.com:deBXOnPXp2vEHu4BAvh7TY2aUIOhT481ohsECftxO0E="
      ];

      # Allows this server to be used as a remote builder
      trusted-users = [
        "root"
        "@wheel"
        "kari"
      ];
    };

    # buildMachines = [
    #   {
    #     # For this to work, the host should be listed in the known hosts for the root user
    #     # To do this, run: sudo su -c 'ssh kari@buidl0.ponkila.com -i /root/.ssh/id_ed25519'
    #     systems = ["aarch64-linux" "i686-linux" "x86_64-linux"];
    #     supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
    #     sshUser = "kari";
    #     protocol = "ssh";
    #     sshKey = "/root/.ssh/id_ed25519";
    #     hostName = "buidl0.ponkila.com";
    #     maxJobs = 20;
    #   }
    # ];
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    extraOptions = ''
      builders-use-substitutes = true

      download-attempts = 3
      connect-timeout = 10
      fallback = true
    '';
  };

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;
}
