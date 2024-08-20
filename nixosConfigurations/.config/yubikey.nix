{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    pinentry-curses
    age-plugin-fido2-hmac

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
  services.yubikey-agent.enable = true;

  # Logging-in
  # nix-shell -p pam_u2f
  # mkdir -p ~/.config/Yubico
  # pamu2fcfg > ~/.config/Yubico/u2f_keys
  security.pam.services = {
    greetd.u2fAuth = true;
    sudo.u2fAuth = true;
    swaylock.u2fAuth = true;
    login.u2fAuth = true;
  };

  # Send notification
  programs.yubikey-touch-detector.enable = true;
}
