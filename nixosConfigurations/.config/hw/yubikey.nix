{ pkgs, ... }: {
  # FIDO2 creds for agenix-rekey
  # age-plugin-fido2-hmac -g > ./master.hmac
  environment.systemPackages = with pkgs; [
    pinentry-curses
    age-plugin-fido2-hmac
  ];
  programs.yubikey-touch-detector.enable = true;

  # Preserve SSH_AUTH_SOCK for sudo so YubiKey-backed SSH keys work
  # This allows nix to fetch private repos when running sudo nixos-rebuild
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';

  # Origin defaults to the hostname; fixed so one registration works fleet-wide
  security.pam = {
    u2f.settings = {
      origin = "pam://coditon";
      appid = "pam://coditon";
    };
    services = {
      greetd.u2fAuth = true;
      sudo.u2fAuth = true;
      hyprlock.u2fAuth = true;
      login.u2fAuth = true;
      sudo.rssh = true;
    };

    # sudo accepts a signature from the agent, so a YubiKey touch replaces the password
    rssh = {
      enable = true;
      settings.auth_key_file = "/etc/ssh/authorized_keys.d/\${user}";
    };
  };
}
