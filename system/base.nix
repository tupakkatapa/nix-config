{ lib
, pkgs
, ...
}: {
  # Pin static UIDs for all systemd units (ephemeral hosts can't keep dynamic UIDs stable)
  imports = [
    (_: {
      options.systemd.services = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          config.serviceConfig.DynamicUser = lib.mkForce false;
        });
      };
    })
  ];

  # Use LTS kernel
  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

  # Set the console keymap
  console.keyMap = "fi";

  # Localization
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "fi_FI.UTF-8";
  };

  # Reset the user and group files on system activation
  users.mutableUsers = false;

  # Only generate an ed25519 key
  services.openssh.hostKeys = lib.mkDefault [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Early OOM killer
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  # Logging daemon
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=10G
    SystemMaxFileSize=128M
    SystemKeepFree=1G
    Compress=yes
    ForwardToSyslog=no
  '';

  # Journald + kernel audit subsystem + auditd daemon
  security.audit.enable = true;
  security.auditd.enable = true;
  security.auditd.settings = {
    max_log_file = 100; # MB per file
    num_logs = 10; # rotate-and-keep 10 files (~1G total)
    max_log_file_action = "ROTATE";
    space_left = 200; # MB
    space_left_action = "SYSLOG";
    admin_space_left = 100;
    admin_space_left_action = "SUSPEND";
    disk_full_action = "SUSPEND";
    disk_error_action = "SUSPEND";
  };

  # Create /bin/bash symlink
  system.activationScripts.binbash = ''
    mkdir -p /bin
    ln -sf ${pkgs.bash}/bin/bash /bin/bash
  '';

  # Essential packages
  environment.systemPackages = with pkgs; [
    btrfs-progs
    htop
    kexec-tools
    lshw
    rsync
    tmux
    vim
    wget
    curl
    pciutils
    lsof
    dig
    jq
    jc
  ];
}
