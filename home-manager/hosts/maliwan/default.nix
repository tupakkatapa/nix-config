{ pkgs
, ...
}: {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [ ../.config/base01/rice01 ];

  xdg.configFile."pipewire-out-switcher/devices.json".text = builtins.toJSON {
    speakers = "alsa_output.pci-0000_c4_00.6.HiFi__Speaker__sink";
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
