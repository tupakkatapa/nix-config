{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.autoScrcpy;
in
{
  options.services.autoScrcpy = {
    enable = lib.mkEnableOption ''
      Automatically start scrcpy when an Android device is connected
    '';

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

    # Trigger user service when Android device is connected
    services.udev.extraRules = ''
      ACTION=="add",\
      SUBSYSTEM=="usb",\
      ENV{ID_USB_INTERFACES}=="*:ff4201:*",\
      TAG+="systemd",\
      ENV{SYSTEMD_USER_WANTS}+="auto-scrcpy.service"
    '';

    # Run as user service for GPU and Wayland access
    systemd.user.services.auto-scrcpy = {
      description = "Auto-start scrcpy for Android device";
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.scrcpy}/bin/scrcpy --render-driver=opengl --max-size=${toString cfg.maxSize} --stay-awake";
      };
    };
  };
}
