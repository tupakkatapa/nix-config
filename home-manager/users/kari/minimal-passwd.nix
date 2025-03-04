{ config
, lib
, pkgs
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
    # "password".rekeyFile = ./secrets/password.age;
    "wg-dinar" = {
      rekeyFile = ./secrets/wg-dinar.age;
      owner = "systemd-network";
    };
    "wg-home" = {
      rekeyFile = ./secrets/wg-home.age;
      owner = "systemd-network";
    };
    "wpa-psk".rekeyFile = ./secrets/wpa-psk.age;
    "ed25519-sk-yubikey" = {
      rekeyFile = ./secrets/ed25519-sk-yubikey.age;
      path = "/home/${user}/.ssh/id_ed25519_sk_yubikey";
      mode = "600";
      owner = user;
      group = "users";
    };
    "ed25519-sk-trezor" = {
      rekeyFile = ./secrets/ed25519-sk-trezor.age;
      path = "/home/${user}/.ssh/id_ed25519_sk_trezor";
      mode = "600";
      owner = user;
      group = "users";
    };
  };

  # Set password
  users.users.${user} = {
    # echo "password" | mkpasswd -s
    # hashedPasswordFile = config.age.secrets.password.path;
  };

  # Enable Trezor support
  services.trezord.enable = true;

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh 755 ${user} ${user} -"
  ];

  # Mount SFTP and bind home directories
  services.sftpMount =
    let
      sftpPrefix = "sftp@192.168.1.8:";
    in
    lib.mkIf (config.networking.hostName != "vladof") {
      enable = true;

      # Define the YubiKey resident key as the identifier and disable automount
      defaults = {
        identityFile = "/home/${user}/.ssh/id_ed25519_sk_yubikey";
        autoMount = false;
      };

      mounts =
        [
          {
            what = "${sftpPrefix}/";
            where = "/mnt/sftp";
          }
        ];

      # Bind mounts are always done after the SFTP mounts
      binds =
        [
          {
            what = "/mnt/sftp/docs";
            where = "/home/${user}/Documents";
          }
          {
            what = "/mnt/sftp/media";
            where = "/home/${user}/Media";
          }
          {
            what = "/mnt/sftp/code/workspace";
            where = "/home/${user}/Workspace";
          }
          {
            what = "/mnt/sftp/dnld";
            where = "/home/${user}/Downloads";
          }
        ];
    };
  # Add SFTP host to root's known hosts for non-interactive authentication
  services.openssh.knownHosts.vladof = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w";
    extraHostNames = [ "192.168.1.8" ];
  };

  home-manager.users."${user}" = {
    imports =
      [
        ./.config/lazygit.nix
      ];

    # Extra SSH config
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "*" = {
          identityFile = [
            config.age.secrets.ed25519-sk-yubikey.path
            config.age.secrets.ed25519-sk-trezor.path
          ];
        };
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
        "node2" = {
          proxyJump = "core@192.168.1.25";
          hostname = "node2.simple";
          user = "core";
        };
      };
      forwardAgent = true;
      addKeysToAgent = "yes";
    };
    services.ssh-agent.enable = true;

    # Signing commits
    programs.git = {
      signing.key = "A3B346665514836DCE851842A2429183508FCEFF";
      signing.signByDefault = true;
      userEmail = "jesse@ponkila.com";
      userName = "tupakkatapa";
    };
    programs.gpg = {
      enable = true;
      homedir = "/home/${user}/.gnupg/trezor";
      settings = {
        default-key = "Tupakkatapa <jesse@ponkila.com>";
        agent-program = "${pkgs.trezor_agent}/bin/trezor-gpg-agent";
      };
    };
    home.packages = with pkgs; [
      trezor-agent
      # trezor-suite
      trezorctl
    ];
  };

  # WPA PSK's
  networking.wireless = {
    networks = {
      "OP9".pskRaw = "ext:psk_op9";
    };
    secretsFile = config.age.secrets.wpa-psk.path;
  };

  # Wireguard
  systemd.network = {
    netdevs = {
      "99-home" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "home";
        };
        wireguardConfig.PrivateKeyFile = config.age.secrets.wg-home.path;
        wireguardPeers = [{
          PublicKey = "UtZe3/06A4jT8BU8C4LhJZnZ+/vqKtw6S/RLScGgU14=";
          AllowedIPs = [ "192.168.1.0/24" "172.16.16.0/24" ];
          Endpoint = [ "coditon.com:51820" ];
          PersistentKeepalive = 25;
        }];
      };
      "99-dinar" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "dinar";
        };
        wireguardConfig.PrivateKeyFile = config.age.secrets.wg-dinar.path;
        wireguardPeers = [{
          PublicKey = "s7XsWWxjl8zi6DTx4KkhjmI1jVseV9KVlc+cInFNyzE=";
          AllowedIPs = [ "192.168.100.0/24" ];
          Endpoint = [ "coin.dinar.fi:51820" ];
          PersistentKeepalive = 25;
        }];
      };
    };
    networks = {
      "99-home" = {
        matchConfig.Name = "home";
        address = [ "172.16.16.3/32" ];
        linkConfig.ActivationPolicy = "manual";
        routes = [
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "172.16.16.0/24";
          }
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "192.168.1.0/24";
          }
        ];
        dns = [ "172.16.16.1" ];
      };
      "99-dinar" = {
        matchConfig.Name = "dinar";
        address = [ "192.168.100.121/32" ];
        linkConfig.ActivationPolicy = "manual";
        routes = [{
          Gateway = "192.168.100.1";
          GatewayOnLink = true;
          Destination = "192.168.100.0/24";
        }];
      };
    };
  };
}
