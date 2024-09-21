_:
let
  user = "kari";
  appData = "/mnt/860/appdata/${user}";
  secretData = "/mnt/860/secrets/${user}";
in
{
  # This file is for when I have the hardware and a stable netboot server to go ephemeral

  /*
    Persistent file memo

    gpg --list-secret-keys --keyid-format=long
    /etc/ssh/ssh_host_ed25519_key
    /etc/ssh/ssh_host_ed25519_key.pub
    ~/.ssh/id_ed25519
    ~/.config/Yubico/u2f_keys
  */

  # Host SSH keys
  services.openssh.hostKeys = [{
    path = "/mnt/860/secrets/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Mount drives
  fileSystems."/mnt/860" = {
    device = "/dev/disk/by-uuid/20cfc618-e1e9-476e-984e-55326b3b5ca7";
    fsType = "ext4";
    # options = ["subvolid=420"];
    neededForBoot = true;
  };
  fileSystems."/mnt/boot" = {
    device = "/dev/disk/by-uuid/CA7C-5C77";
    fsType = "auto";
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d ${appData}                755 ${user} ${user} -"
    "d ${appData}/firefox        755 ${user} ${user} -"
    "d ${appData}/guitarix       755 ${user} ${user} -"
    "d ${appData}/plexamp        755 ${user} ${user} -"
    "d ${appData}/steam          755 ${user} ${user} -"
    "d ${appData}/sublime-merge  755 ${user} ${user} -"

    "d ${secretData}             700 ${user} ${user} -"
    "d ${secretData}/gnupg       700 ${user} ${user} -"
    "d ${secretData}/yubico      755 ${user} ${user} -"

    "d /mnt/860                  755 root root -"
    "d /mnt/860/appdata          755 root root -"
    "d /mnt/860/games            755 root root -"
    "d /mnt/860/nix-config       777 root root -"
    "d /mnt/860/secrets          755 root root -"

    "d /mnt/boot                 755 root root -"
    "d /mnt/sftp                 755 root root -"
  ];

  # Set local flake path to be able to be referenced
  environment.variables.FLAKE_DIR = "/mnt/860/nix-config";

  # Bind to persistent drive to preserve
  fileSystems = {
    "/home/${user}/.mozilla" = {
      device = "${appData}/firefox";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.steam" = {
      device = "${appData}/steam";
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
  };
}
