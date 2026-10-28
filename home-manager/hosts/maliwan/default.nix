{ pkgs
, ...
}:
let
  dock = "Lenovo Group Limited P34w-20 VVE53307";
in
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [ ../.config/base01/rice01 ];

  # Docked, the panel mirrors; undocked, Hyprland drops the mirror
  wayland.windowManager.hyprland.settings.monitor = [
    "desc:${dock}, 3440x1440@59.97, 0x0, 1"
    "eDP-1, preferred, 3440x0, 1, mirror, desc:${dock}"
  ];

  xdg.configFile."pipewire-out-switcher/devices.json".text = builtins.toJSON {
    speakers = "alsa_output.pci-*.HiFi__HDMI*__sink";
    headset = "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo";
    earbuds = "bluez_output.78_C1_1D_EA_46_EF.1";
  };

  # Low battery: one popup per level crossed; every 1% in the last 5%
  systemd.user.services.bat-warn = {
    Unit.Description = "Low-battery notification check";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.wm-helpers}/bin/bat-warn 20 10 5 4 3 2 1";
    };
  };
  systemd.user.timers.bat-warn = {
    Unit.Description = "Run bat-warn every minute";
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
