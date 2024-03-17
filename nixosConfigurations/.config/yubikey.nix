{
  pkgs,
  config,
  lib,
  ...
}: {
  # Yubico's official tools
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-manager-qt
    yubikey-personalization
    yubikey-personalization-gui
    yubico-piv-tool
    yubioath-flutter
  ];
  services.udev.packages = [
    pkgs.yubikey-personalization
  ];

  # Lock screen when unplugged
  services.udev.extraRules = ''
    ACTION=="remove",\
    ENV{ID_BUS}=="usb",\
    ENV{ID_MODEL_ID}=="0407",\
    ENV{ID_VENDOR_ID}=="1050",\
    ENV{ID_VENDOR}=="Yubico",\
    RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
  '';
  services.pcscd.enable = true;

  # Logging-in
  security.pam.services = {
    greetd.u2fAuth = true;
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    swaylock.u2fAuth = true;
  };

  # Send notification
  programs.yubikey-touch-detector.enable = true;
}
