{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./nix-settings.nix
  ];

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
    fuse-overlayfs
    bind
    file
    vim
    nix
  ];

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
