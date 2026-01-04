{ pkgs, ... }: {
  # FIDO2 creds for agenix-rekey
  # age-plugin-fido2-hmac -g > ./master.hmac
  environment.systemPackages = with pkgs; [
    pinentry-curses
    age-plugin-fido2-hmac
    yubikey-manager
  ];
  # yubikey-agent is for PIV, not needed for FIDO2 (ED25519-SK keys)
  # Using ssh-agent from home-manager instead (services.ssh-agent.enable)
  services.yubikey-agent.enable = false;
  programs.yubikey-touch-detector.enable = true;

  # SSH agent auth for sudo - preserves SSH_AUTH_SOCK and allows YubiKey touch for sudo
  # This allows nix to fetch private repos when running sudo nixos-rebuild
  security.pam.sshAgentAuth.enable = true;

  # U2F
  # Logging-in
  # nix-shell -p pam_u2f
  # mkdir -p ~/.config/Yubico
  # pamu2fcfg > ~/.config/Yubico/u2f_keys
  security.pam.services = {
    greetd.u2fAuth = true;
    swaylock.u2fAuth = true;
    login.u2fAuth = true;
  };
}
