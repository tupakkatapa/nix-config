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
    # Wrap with NVIDIA libs — setcap wrapper strips LD_LIBRARY_PATH
    package = pkgs.sunshine.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/sunshine \
          --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
      '';
    });
    settings = {
      keyboard = "enabled";
      always_send_scancodes = "enabled";
      key_repeat_delay = 500;
      key_repeat_frequency = 24;
      stream_audio = "enabled";
      ping_timeout = 20000;

      # NVENC tuning for LAN streaming
      nvenc_preset = 1; # lowest latency
      nvenc_twopass = "quarter_res";
      nvenc_vbv_increase = 100; # allow 2x frame size for scene changes
    };
  };

  # Sunshine module only opens TCP 47984,47989,47990 and UDP 47998,47999
  networking.firewall.allowedUDPPorts = [ 48000 48002 48010 ];
  networking.firewall.allowedTCPPorts = [ 48010 ];

  systemd.user.services.sunshine = {
    wantedBy = [ "default.target" ];
    wants = lib.mkForce [ ];
    after = lib.mkForce [ ];
    partOf = lib.mkForce [ ];
    serviceConfig.RestartSec = lib.mkForce "5s";
    environment = {
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      WAYLAND_DISPLAY = "wayland-0";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
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

  # Keep Intel VA-API as fallback
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
  ];
}
