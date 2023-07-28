{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
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
      ];
    };

    buildMachines = [
      {
        systems = ["aarch64-linux" "i686-linux" "x86_64-linux"];
        supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
        sshUser = "kari";
        protocol = "ssh-ng";
        sshKey = "/root/.ssh/id_ed25519";
        hostName = "buidl0.ponkila.com";
        maxJobs = 20;
      }
      {
        systems = ["aarch64-linux" "armv7l-linux"];
        supportedFeatures = ["benchmark" "big-parallel" "gccarch-armv8-a" "kvm" "nixos-test"];
        sshUser = "kari";
        protocol = "ssh-ng";
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
  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
  ];
  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelParams = [
      "boot.shell_on_fail"

      "mitigations=off"
      "l1tf=off"
      "mds=off"
      "no_stf_barrier"
      "noibpb"
      "noibrs"
      "nopti"
      "nospec_store_bypass_disable"
      "nospectre_v1"
      "nospectre_v2"
      "tsx=on"
      "tsx_async_abort=off"
    ];
    kernelPackages = lib.mkDefault (pkgs.linuxPackagesFor (pkgs.linux_latest));
    # Increase tmpfs (default: "50%")
    tmp.tmpfsSize = "80%";
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    kexec-tools
    fuse-overlayfs
    bind
    file
    vim
  ];

  # Plymouth boot splash screen
  # Module https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/plymouth.nix
  # Reference https://blog.sidhartharya.com/using-custom-plymouth-theme-on-nixos/
  boot.plymouth.enable = true;

  # Enable podman with DNS
  virtualisation.podman = {
    enable = true;
    # dnsname allows containers to use ${name}.dns.podman to reach each other
    # on the same host instead of using hard-coded IPs.
    # NOTE: --net must be the same on the containers, and not eq "host"
    # TODO: extend this with flannel ontop of wireguard for cross-node comms
    defaultNetwork.settings = {dns_enabled = true;};
  };

  # Reboots hanged system
  systemd.watchdog.device = "/dev/watchdog";
  systemd.watchdog.runtimeTime = "30s";

  # Zram swap
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.memoryPercent = 100;

  # Allow passwordless sudo from wheel group
  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
    execWheelOnly = true;
  };
}
