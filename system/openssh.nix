{ lib
, ...
}: {
  # Enable strict OpenSSH
  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault true;
    allowSFTP = lib.mkDefault false;
    extraConfig = ''
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding yes
      AuthenticationMethods publickey
      X11Forwarding no
    '';
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
