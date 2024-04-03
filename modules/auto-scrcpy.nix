{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.autoScrcpy;
in {
  options.services.autoScrcpy = {
    enable = lib.mkEnableOption ''
      Automatically start scrcpy when an Android device is connected
    '';

    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "The username of the user for whom the scrcpy service will be enabled.";
      };
      id = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "The user ID for the specified user.";
      };
    };

    waylandDisplay = lib.mkOption {
      type = lib.types.str;
      default = "wayland-0";
      description = "The Wayland display server to use.";
    };

    # This does not work, yet
    # https://github.com/Genymobile/scrcpy/issues/4760
    maxSize = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        Limit both the width and height of the video to value. The other dimension is computed so that the device aspect-ratio is preserved.
        Default is 0 (unlimited).
      '';
    };
  };

  config = lib.mkIf config.services.autoScrcpy.enable {
    environment.systemPackages = with pkgs; [
      scrcpy
      android-tools
    ];

    services.udev.extraRules = ''
      ACTION=="add",\
      SUBSYSTEM=="usb",\
      ENV{ID_USB_INTERFACES}=="*:ff4201:*",\
      TAG+="systemd",\
      ENV{SYSTEMD_WANTS}+="auto-scrcpy.service"
    '';

    systemd.services.auto-scrcpy = {
      description = "Auto-start scrcpy for Android device";
      serviceConfig = {
        Type = "simple";
        User = cfg.user.name;
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.scrcpy}/bin/scrcpy --max-size=${toString cfg.maxSize} --power-off-on-close --turn-screen-off --stay-awake";
      };
      environment = {
        XDG_RUNTIME_DIR = "/run/user/${toString cfg.user.id}";
        WAYLAND_DISPLAY = cfg.waylandDisplay;
      };
      wantedBy = ["multi-user.target"];
    };
  };
}
