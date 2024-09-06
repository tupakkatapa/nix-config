{ config
, lib
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Secrets
  age.secrets = {
    "password".file = ./secrets/password.age;
    "wg-dinar".file = ./secrets/wg-dinar.age;
    "ed25519-sk" = {
      file = ./secrets/ed25519-sk.age;
      path = "/home/${user}/.ssh/id_ed25519_sk";
      mode = "600";
      owner = user;
      group = user;
    };
  };

  # Set password
  users.users.${user} = {
    # echo "password" | mkpasswd -s
    hashedPasswordFile = config.age.secrets.password.path;
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh 755 ${user} ${user} -"
  ];

  # Mount SFTP and bind home directories
  services.sftpClient = lib.mkIf (config.networking.hostName != "vladof") {
    enable = true;
    defaultIdentityFile = "/home/${user}/.ssh/id_ed25519";
    mounts = [{
      what = "sftp@192.168.1.8:/";
      where = "/mnt/sftp";
    }];
    binds = [
      {
        what = "/mnt/sftp/docs";
        where = "/home/${user}/Documents";
      }
      {
        what = "/mnt/sftp/media";
        where = "/home/${user}/Media";
      }
      {
        what = "/mnt/sftp/dnld";
        where = "/home/${user}/Downloads";
      }
      {
        what = "/mnt/sftp/code/workspace";
        where = "/home/${user}/Workspace";
      }
    ];
  };

  home-manager.users."${user}" = {
    # Extra SSH config
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "192.168.1.*".extraOptions."StrictHostKeyChecking" = "no";
        "192.168.100.*" = {
          user = "core";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "192.168.1.171" = {
          user = "core";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "vladof" = {
          hostname = "192.168.1.8";
          extraOptions."StrictHostKeyChecking" = "no";
        };
      };
      forwardAgent = true;
      addKeysToAgent = "yes";
    };
    services.ssh-agent.enable = true;

    # Signing commits
    programs.git = {
      signing.key = "773DC99EDAF29D356155DC91269CF32D790D1789";
      signing.signByDefault = true;
      userEmail = "jesse@ponkila.com";
      userName = "tupakkatapa";
    };
  };

  # Wireguard
  networking.wg-quick.interfaces."wg0" = {
    autostart = true;
    configFile = config.age.secrets.wg-dinar.path;
  };
}
