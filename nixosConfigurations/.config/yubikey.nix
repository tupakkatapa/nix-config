{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    pinentry-curses
    age-plugin-fido2-hmac
    yubikey-manager
  ];
  services.yubikey-agent.enable = true;
  programs.yubikey-touch-detector.enable = true;

  # U2F
  # Logging-in
  # nix-shell -p pam_u2f
  # mkdir -p ~/.config/Yubico
  # pamu2fcfg > ~/.config/Yubico/u2f_keys
  security.pam = {
    services = {
      greetd.u2fAuth = true;
      sudo.u2fAuth = true;
      swaylock.u2fAuth = true;
      login.u2fAuth = true;
    };
  };
}
