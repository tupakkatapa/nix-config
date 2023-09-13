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

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "http://buidl0.ponkila.com:5000"
        "http://buidl1.ponkila.com:5000"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "buidl0.ponkila.com:qJZUo9Aji8cTc0v6hIGqbWT8sy+IT/rmSKUFTfhVGGw="
        "buidl1.ponkila.com:ZIIETN3bdTS4DtymDmVGKqG6UOPy4gU89DPCfAKDcx8="
      ];

      # Allows this server to be used as a remote builder
      trusted-users = [
        "root"
        "@wheel"
        "kari"
      ];
    };

    buildMachines = [
      {
        systems = ["aarch64-linux" "i686-linux" "x86_64-linux"];
        supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
        sshUser = "kari";
        protocol = "ssh";
        sshKey = "/root/.ssh/id_ed25519";
        hostName = "buidl0.ponkila.com";
        maxJobs = 20;
      }
      {
        systems = ["aarch64-linux" "armv7l-linux"];
        supportedFeatures = ["benchmark" "big-parallel" "gccarch-armv8-a" "kvm" "nixos-test"];
        sshUser = "kari";
        protocol = "ssh";
        sshKey = "/root/.ssh/id_ed25519";
        hostName = "buidl1.ponkila.com";
        maxJobs = 16;
      }
    ];
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;
}
