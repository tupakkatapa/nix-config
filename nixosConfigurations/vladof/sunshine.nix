{ pkgs, lib, ... }:
let
  user = "kari";
in
{
  # Sunshine streaming server
  services.sunshine = {
    enable = true;
    autoStart = false; # graphical-session.target not available under Cage
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      keyboard = "enabled";
      always_send_scancodes = "enabled";
      key_repeat_delay = 500;
      key_repeat_frequency = 24;
      stream_audio = "enabled";
    };
  };
  systemd.user.services.sunshine = {
    wantedBy = [ "default.target" ];
    wants = lib.mkForce [ ];
    after = lib.mkForce [ ];
    partOf = lib.mkForce [ ];
    serviceConfig.RestartSec = lib.mkForce "5s";
  };

  # Restart Sunshine when Cage starts (separate service to avoid PAM conflicts)
  systemd.services.sunshine-restarter = {
    description = "Restart Sunshine after Cage";
    after = [ "cage-tty1.service" ];
    bindsTo = [ "cage-tty1.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user --machine=${user}@ restart sunshine";
    };
  };

  # uinput access for Sunshine virtual input devices
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", GROUP="input", MODE="0660"
  '';

  # Force HDMI 1080p output without connected display (virtual display)
  hardware.display.edid.modelines."1920x1080" =
    "148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync";
  hardware.display.outputs."HDMI-A-1" = {
    edid = "1920x1080.bin";
    mode = "1920x1080@60e";
  };

  # Intel VA-API hardware encoding for Sunshine
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD (Broadwell+)
      intel-vaapi-driver # i965 (older Intel)
    ];
  };
}
