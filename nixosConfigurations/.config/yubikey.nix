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

  # Logging-in
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  # Send notification
  programs.yubikey-touch-detector.enable = true;
}
