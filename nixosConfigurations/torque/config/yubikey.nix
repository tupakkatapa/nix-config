{
  pkgs,
  config,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Yubico's official tools
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
