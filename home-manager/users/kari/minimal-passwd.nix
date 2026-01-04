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
    "ed25519-sk-yubikey-2" = {
      rekeyFile = ./secrets/ed25519-sk-yubikey-2.age;
      path = "/home/${user}/.ssh/id_ed25519_sk_yubikey_2";
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
    "nix-access-tokens".rekeyFile = ./secrets/nix-access-tokens.age;
  };

  # Append access tokens to nix.conf to avoid rate limits
  nix.extraOptions = ''
    !include ${config.age.secrets.nix-access-tokens.path}
  '';

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
  services.sftpClient = lib.mkIf (config.networking.hostName != "vladof") {
    enable = true;

    # Define the YubiKey resident key as the identifier and disable automount
    defaults = {
      identityFile = [
        config.age.secrets.ed25519-sk-yubikey.path
        config.age.secrets.ed25519-sk-yubikey-2.path
        config.age.secrets.ed25519-sk-trezor.path
      ];
      autoMount = false;
    };

    mounts = [{
      what = "sftp@10.42.0.8:/";
      where = "/mnt/sftp";
    }];

    # Bind mounts are always done after the SFTP mounts
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
        what = "/mnt/sftp/appdata/retroarch";
        where = "/home/${user}/.config/retroarch";
      }
    ];
  };
  # Add SFTP host to root's known hosts for non-interactive authentication
  services.openssh.knownHosts.vladof = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w";
    extraHostNames = [ "10.42.0.8" ];
  };

  home-manager.users."${user}" = {
    # Extra SSH config
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          identityFile = [
            config.age.secrets.ed25519-sk-yubikey.path
            config.age.secrets.ed25519-sk-yubikey-2.path
            config.age.secrets.ed25519-sk-trezor.path
          ];
          forwardAgent = true;
          addKeysToAgent = "yes";
        };
        "hyperion" = {
          user = "core";
          hostname = "10.42.0.1";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "torgue" = {
          hostname = "10.42.0.7";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "vladof" = {
          hostname = "10.42.0.8";
          extraOptions."StrictHostKeyChecking" = "no";
        };
        "10.42.0.*".extraOptions."StrictHostKeyChecking" = "no";
      };
    };
    services.ssh-agent.enable = true;

    # Electronic mail
    accounts.email.accounts."ponkila" = {
      address = "jesse@ponkila.com";
      userName = "jesse@ponkila.com";
      realName = "Jesse Karjalainen";
      primary = true;
      imap = {
        host = "mail.your-server.de";
        port = 143;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      smtp = {
        host = "mail.your-server.de";
        port = 587;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      msmtp.enable = true;
    };
    programs.msmtp.enable = true;

    # Git signing and identity
    programs.git = {
      signing = {
        format = "ssh";
        key = "/home/${user}/.ssh/id_ed25519_sk_yubikey";
        signByDefault = true;
      };
      settings = {
        user = {
          email = "jesse@ponkila.com";
          name = "Jesse Karjalainen";
        };
        sendemail.smtpserver = "${pkgs.msmtp}/bin/msmtp";
      };
    };
    programs.gpg = {
      enable = true;
      homedir = "/home/${user}/.gnupg/trezor";
      settings = {
        default-key = "Jesse Karjalainen <jesse@ponkila.com>";
        agent-program = "${pkgs.trezor-agent}/bin/trezor-gpg-agent";
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
      "Pixel_1253".pskRaw = "ext:psk_op9";
      "hyperion-2g".pskRaw = "ext:psk_hyp";
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
          PublicKey = "jRlrkYOWatx3pvJPt22uuWDiWJ8K9d+teJ2IEiMJ3SA=";
          AllowedIPs = [ "10.42.0.0/24" "172.16.16.0/24" ];
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
        linkConfig.ActivationPolicy = if config.networking.hostName == "maliwan" then "up" else "manual";
        routes = [
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "172.16.16.0/24";
          }
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "10.42.0.0/24";
          }
        ];
        dns = [ "10.42.0.1" ];
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
