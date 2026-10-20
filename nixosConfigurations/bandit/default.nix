{ lib, ... }: {
  networking.hostName = "bandit";

  # Disable firewall
  networking.firewall.enable = false;

  imports = [
    ../.config/hw/yubikey.nix
  ];

  # No agenix here, so there is no password to prompt for
  security.sudo.extraRules = [{
    users = [ "core" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # No persistence, / is tmpfs
  services.journald.extraConfig = lib.mkForce ''
    Storage=volatile
    RuntimeMaxUse=256M
    RuntimeMaxFileSize=32M
    Compress=yes
    ForwardToSyslog=no
  '';
  security.auditd.settings = {
    max_log_file = lib.mkForce 16; # MB per file
    num_logs = lib.mkForce 4; # ~64M total
    space_left = lib.mkForce 32;
    admin_space_left = lib.mkForce 16;
  };
}
