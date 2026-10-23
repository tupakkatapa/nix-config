{ inputs
, config
, lib
, ...
}:
let
  builds = builtins.elem config.networking.hostName [ "torgue" "maliwan" ];
in
{
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
      # Trust flake.nix nixConfig
      accept-flake-config = true;
      # Allow impure evaluation by default
      pure-eval = false;
      # Don't warn about dirty Git trees
      warn-dirty = false;
      # @wheel is needed to receive unsigned closures from nixos-rebuild
      # --target-host, which copies as the SSH user rather than through sudo
      trusted-users = [ "root" "@wheel" ];
      # vladof builds; local builds only via --max-jobs auto (e.g. maliwan offline)
      max-jobs = lib.mkIf builds 0;

      # hyperion builds the netboot images, so it must not trust a cache
      # vladof can sign for
      extra-substituters = [
        "https://cache.nixos.org"
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ] ++ lib.optionals (config.networking.hostName != "hyperion") [
        "http://10.42.0.8:5000" # vladof harmonia (LAN binary cache)
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ] ++ lib.optionals (config.networking.hostName != "hyperion") [
        "vladof.coditon.com-1:VNlHYPLDol9HKt8Q8HQLAEkhwB7B1KvbWbYHNkyfuMI="
      ];
    };

    distributedBuilds = true;
    buildMachines = lib.optionals builds [{
      # nix-daemon connects as root: no ssh alias, and resolved skips single-label names
      hostName = "10.42.0.8";
      sshUser = "nixremote";
      sshKey = (lib.findFirst (k: k.type == "ed25519") null config.services.openssh.hostKeys).path;
      protocol = "ssh-ng";
      systems = [ "x86_64-linux" ];
      maxJobs = 8;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }];
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
}
