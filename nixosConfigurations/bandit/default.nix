{ lib
, ...
}: {
  networking.hostName = "bandit";
  console.keyMap = "fi";

  # Autologin
  services.getty.autologinUser = "core";

  # Enable SSH
  services.openssh.enable = true;

  # Allow passwordless sudo from wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
    execWheelOnly = true;
  };
}
