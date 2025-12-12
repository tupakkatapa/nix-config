{ inputs
, config
, lib
, ...
}: {
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mkDefault (lib.mapAttrs (_: value: { flake = value; }) inputs);

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mkDefault (lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry);

    # Disable nix channels. Use flakes instead.
    channel.enable = false;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      # Allows this server to be used as a remote builder
      trusted-users = [ "root" "@wheel" ];

      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
    };

    # buildMachines = [
    #   {
    #     # For this to work, the host should be listed in the known hosts for the root user
    #     # To do this, run: sudo su -c 'ssh kari@buidl0.ponkila.com -i /root/.ssh/id_ed25519'
    #     systems = ["aarch64-linux" "i686-linux" "x86_64-linux"];
    #     supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
    #     sshUser = "core";
    #     protocol = "ssh";
    #     sshKey = "/root/.ssh/id_ed25519";
    #     hostName = "192.168.100.5";
    #     maxJobs = 20;
    #   }
    # ];
    distributedBuilds = true;
    extraOptions = ''
      # optional, useful when the builder has a faster internet connection than yours
      builders-use-substitutes = true

      # fallback if substituter down
      download-attempts = 3
      connect-timeout = 5
      fallback = true
    '';
  };

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;

  # Allow insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "python3.13-ecdsa-0.19.1" # TODO: dependency of trezor-agent and yubikey-manager, has CVE-2024-23342
  ];
}
