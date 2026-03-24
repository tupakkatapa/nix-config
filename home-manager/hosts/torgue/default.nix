{ ...
}: {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [ ../.config/base01/rice01 ];

  xdg.configFile."pipewire-out-switcher/devices.json".text = builtins.toJSON {
    speakers = "alsa_output.pci-0000_0c_00.4.analog-stereo";
    headset = "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo";
    earbuds = "bluez_output.78_C1_1D_EA_46_EF.1";
  };
}
