_:
let
  user = "core";
  dataDir = "/mnt/860";
  appData = "${dataDir}/appdata/${user}";
in
{
  imports = [
    ../.config/gaming-amd.nix
    ../.config/pipewire.nix
    ../.config/retroarch.nix
  ];

  networking.hostName = "tediore";

  # Autologin
  services.getty.autologinUser = user;

  # Start sway
  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty? ]] && sudo /run/current-system/sw/bin/lock this 
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  # Mount drives
  fileSystems."/mnt/860" = {
    device = "/dev/disk/by-uuid/20cfc618-e1e9-476e-984e-55326b3b5ca7";
    fsType = "ext4";
    neededForBoot = true;
  };

  # Bind to persistent drive to preserve
  fileSystems."/home/${user}/.steam" = {
    device = "${appData}/steam";
    options = [ "bind" "mode=755" ];
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d ${appData}                755 ${user} ${user} -"
    "d ${appData}/steam          755 ${user} ${user} -"

    "d ${dataDir}                755 root root -"
    "d ${dataDir}/games          755 root root -"
  ];
}

