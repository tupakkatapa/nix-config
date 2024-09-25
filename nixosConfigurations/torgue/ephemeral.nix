_:
let
  user = "kari";
  dataDir = "/mnt/860";
  appData = "${dataDir}/appdata/${user}";
  secretData = "${dataDir}/secrets/${user}";
in
{
  # Host SSH keys
  services.openssh.hostKeys = [{
    path = "${dataDir}/secrets/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Mount drives
  fileSystems."${dataDir}" = {
    device = "/dev/disk/by-uuid/20cfc618-e1e9-476e-984e-55326b3b5ca7";
    fsType = "ext4";
    neededForBoot = true;
  };
  fileSystems."/mnt/boot" = {
    device = "/dev/disk/by-uuid/CA7C-5C77";
    fsType = "auto";
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/${user}/.config     755 ${user} ${user} -"

    "d ${appData}                755 ${user} ${user} -"
    "d ${appData}/firefox        755 ${user} ${user} -"
    "d ${appData}/guitarix       755 ${user} ${user} -"
    "d ${appData}/plexamp        755 ${user} ${user} -"
    "d ${appData}/sublime-merge  755 ${user} ${user} -"

    "d ${secretData}             700 ${user} ${user} -"
    "d ${secretData}/gnupg       700 ${user} ${user} -"
    "d ${secretData}/yubico      755 ${user} ${user} -"

    "d ${dataDir}                755 root root -"
    "d ${dataDir}/appdata        755 root root -"
    "d ${dataDir}/nix-config     777 root root -"
    "d ${dataDir}/secrets        755 root root -"

    "d /mnt/boot                 755 root root -"
    "d /mnt/sftp                 755 root root -"
  ];

  # Set local flake path to be able to be referenced
  environment.variables.FLAKE_DIR = "${dataDir}/nix-config";

  # Bind to persistent drive to preserve
  fileSystems = {
    "/home/${user}/.mozilla" = {
      device = "${appData}/firefox";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.config/Plexamp" = {
      device = "${appData}/plexamp";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.config/guitarix" = {
      device = "${appData}/guitarix";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.config/sublime-merge" = {
      device = "${appData}/sublime-merge";
      options = [ "bind" "mode=700" ];
    };
    "/home/${user}/.config/Yubico" = {
      device = "${secretData}/yubico";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.gnupg" = {
      device = "${secretData}/gnupg";
      options = [ "bind" "mode=700" ];
    };
    "/home/${user}/.ssh" = {
      device = "${secretData}/ssh";
      options = [ "bind" "mode=700" ];
    };
    "/home/${user}/nix-config" = {
      device = "${dataDir}/nix-config";
      options = [ "bind" "mode=777" ];
    };
  };
}
