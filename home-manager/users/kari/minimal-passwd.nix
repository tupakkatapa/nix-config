{ pkgs
, config
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
    "password".rekeyFile = ./secrets/password.age;
    "wg-dinar".rekeyFile = ./secrets/wg-dinar.age;
    "ed25519-sk" = {
      rekeyFile = ./secrets/ed25519-sk.age;
      path = "/home/${user}/.ssh/id_ed25519_sk";
      mode = "600";
      owner = user;
      group = user;
    };
    "yubico-u2f-keys" = {
      rekeyFile = ./secrets/yubico-u2f-keys.age;
      owner = user;
      group = user;
      mode = "644";
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

  # Yubikey
  environment.systemPackages = with pkgs; [
    pinentry-curses
    age-plugin-fido2-hmac
    yubikey-manager
  ];
  services.yubikey-agent.enable = true;
  programs.yubikey-touch-detector.enable = true;

  # U2F
  security.pam = {
    u2f.settings.authFile = config.age.secrets."yubico-u2f-keys".path;
    services = {
      greetd.u2fAuth = true;
      sudo.u2fAuth = true;
      swaylock.u2fAuth = true;
      login.u2fAuth = true;
    };
  };

  # Mount SFTP and bind home directories
  services.sftpClient =
    let
      sftpPrefix = "sftp@192.168.1.8:";
    in
    lib.mkIf (config.networking.hostName != "vladof") {
      enable = true;
      defaultIdentityFile = "/home/${user}/.ssh/id_ed25519";
      mounts =
        [
          {
            what = "${sftpPrefix}/";
            where = "/mnt/sftp";
          }
          {
            what = "${sftpPrefix}/docs";
            where = "/home/${user}/Documents";
          }
          {
            what = "${sftpPrefix}/media";
            where = "/home/${user}/Media";
          }
          {
            what = "${sftpPrefix}/code/workspace";
            where = "/home/${user}/Workspace";
          }
          {
            what = "${sftpPrefix}/dnld";
            where = "/home/${user}/Downloads";
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
