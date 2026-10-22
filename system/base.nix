{ lib
, pkgs
, config
, ...
}:
let
  # Without a disk behind /var/log, logs live in RAM; Vector ships them to Loki
  persistentLogs = config.fileSystems ? "/var/log/journal";
in
{
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
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "fi_FI.UTF-8/UTF-8"
  ];

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
  services.journald.extraConfig =
    if persistentLogs then ''
      Storage=persistent
      SystemMaxUse=10G
      SystemMaxFileSize=128M
      SystemKeepFree=1G
      Compress=yes
      ForwardToSyslog=no
    '' else ''
      Storage=volatile
      RuntimeMaxUse=256M
      RuntimeMaxFileSize=32M
      Compress=yes
      ForwardToSyslog=no
    '';

  # Journald + kernel audit subsystem + auditd daemon
  security.audit.enable = true;
  security.auditd.enable = true;

  # Audit rules, the subsystem records little without them. Watches only,
  # execve syscall rules would flood the 1G budget.
  security.audit.rules = [
    "-w /etc/shadow -p wa -k identity"
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/group -p wa -k identity"
    "-w /run/wrappers/bin/sudo -p x -k privilege"
    "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k modules"
  ];
  security.auditd.settings = {
    max_log_file = if persistentLogs then 100 else 16; # MB per file
    num_logs = if persistentLogs then 10 else 4; # ~1G or ~64M total
    max_log_file_action = "ROTATE";
    space_left = if persistentLogs then 200 else 32; # MB
    space_left_action = "SYSLOG";
    admin_space_left = if persistentLogs then 100 else 16;
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
