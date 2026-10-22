{ pkgs
, unstable
, config
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal-gui version
  imports = [ ./minimal-gui.nix ];

  age.secrets = {
    "wg-home" = {
      rekeyFile = ./secrets/wg-home.age;
      owner = "systemd-network";
    };
    "iwd-hyperion" = {
      rekeyFile = ./secrets/iwd-hyperion.age;
      path = "/etc/iwd/hyperion-2g.psk";
      mode = "0600";
    };
    "iwd-pixel" = {
      rekeyFile = ./secrets/iwd-pixel.age;
      path = "/etc/iwd/Pixel_1253.psk";
      mode = "0600";
    };
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
  };

  # agenix drops the key files here
  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh 755 ${user} ${user} -"
  ];

  # Required for hyprlock via home-manager
  security.pam.services.hyprlock = { };

  # Trezor hardware wallet
  services.trezord.enable = true;

  # Passwordless on-demand SFTP mount at login (sshfs auth still needs a YubiKey touch)
  security.sudo.extraRules = [{
    users = [ user ];
    commands = [
      { command = "/run/wrappers/bin/mount /mnt/sftp"; options = [ "NOPASSWD" ]; }
      { command = "/run/wrappers/bin/umount /mnt/sftp"; options = [ "NOPASSWD" ]; }
    ];
  }];

  networking.firewall.checkReversePath = "loose"; # Breaks with SuppressPrefixLength = 0

  # Home-manager config
  home-manager.users."${user}" = {
    xdg.userDirs = {
      enable = true;
      createDirectories = false;
      setSessionVariables = true;
      download = "/mnt/sftp/dnld";
      documents = "/mnt/sftp/docs";
    };

    programs.ssh.settings = {
      "*".IdentityFile = [
        config.age.secrets.ed25519-sk-yubikey.path
        config.age.secrets.ed25519-sk-yubikey-2.path
        config.age.secrets.ed25519-sk-trezor.path
      ];
      # A key used once is then there for forwarded sudo and signing
      "*".AddKeysToAgent = "yes";
    };
    services.ssh-agent.enable = true;

    # Forwarded signing requests reach an agent with no tty
    systemd.user.services.ssh-agent.Service.Environment = [
      # The agent starts before Hyprland exports its display
      "SSH_ASKPASS=${pkgs.writeShellScript "ssh-askpass-session" ''
        while IFS= read -r var; do export "$var"; done < <(
          ${pkgs.systemd}/bin/systemctl --user show-environment | ${pkgs.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|DISPLAY)='
        )
        exec ${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass "$@"
      ''}"
      "SSH_ASKPASS_REQUIRE=force"
    ];

    programs.git.signing.key = "/home/${user}/.ssh/id_ed25519_sk_yubikey";

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
    programs.git.settings.sendemail.smtpserver = "${pkgs.msmtp}/bin/msmtp";

    # oterm
    xdg.dataFile."oterm/config.json".text = builtins.toJSON {
      mcpServers = {
        searxng = {
          command = "npx";
          args = [ "-y" "mcp-searxng" ];
          env = {
            SEARXNG_URL = "https://search.coditon.com";
            NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
          };
        };
        filesystem = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/${user}" ];
        };
        fetch = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-fetch" ];
        };
        git = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-git" ];
        };
      };
      theme = "gruvbox";
      splash-screen = false;
    };

    # Use specific startup
    wayland.windowManager.hyprland.settings.exec-once =
      let
        # User-level variable, cannot use $BROWSER as might not be set yet
        browser = config.home-manager.users."${user}".home.sessionVariables.BROWSER;
        browserFlags = profile: if browser == "firefox" then "--new-instance -P ${profile}" else "";
      in
      [
        # Open programs on specific workspaces
        "[workspace 4 silent] ${browser} ${browserFlags "personal"} https://web.whatsapp.com https://web.telegram.org/ https://discord.com/channels/@me https://outlook.live.com/mail/0/"
        "[workspace 5 silent] ${browser} ${browserFlags "work"} https://app.slack.com/client https://mail.google.com/mail https://calendar.google.com/calendar https://drive.google.com/drive/home https://linear.app/inform-re/inbox"
      ]
      ++ (if config.networking.hostName != "maliwan" then [
        # Open terminal with SFTP mount on login
        "foot -e $SHELL -c 'echo \"\\$ sudo mount /mnt/sftp\" && sudo mount /mnt/sftp && sleep 1 || read -p \"Press enter to continue..\"'"
      ] else [ ]);

    home.packages = (with pkgs; [
      android-tools
      monitor-adjust
      guitarix
      gxplugins-lv2
      crosspipe
      wireguard-go
      wireguard-tools
      lxqt.lxqt-openssh-askpass

      # Desktop fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only

      # Trezor (override: keyring 25.7.0 not yet in nixpkgs)
      (trezorctl.overridePythonAttrs (old: {
        pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "keyring" ];
      }))

    ]) ++
    (with unstable; [
      oterm
    ]);
  };

  systemd.network = {
    netdevs = {
      "99-home" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "home";
          # Match hyperion's wg0, else the return path depends on PMTUD
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-home.path;
          FirewallMark = 34952;
        };
        wireguardPeers = [{
          PublicKey = "jRlrkYOWatx3pvJPt22uuWDiWJ8K9d+teJ2IEiMJ3SA=";
          AllowedIPs = [ "0.0.0.0/0" "10.42.0.0/24" "172.16.16.0/24" "fd42:42:42:1::/64" "fd42:42:42:3::/64" ];
          Endpoint = [ "vpn.coditon.com:51820" ];
          PersistentKeepalive = 25;
        }];
      };
    };
    networks = {
      "99-home" = {
        matchConfig.Name = "home";
        address = [ "172.16.16.3/32" "fd42:42:42:3::3/128" ];
        linkConfig.ActivationPolicy = if config.networking.hostName == "maliwan" then "up" else "manual";
        routingPolicyRules = [
          # The tunnel's own packets go out the uplink
          {
            FirewallMark = 34952;
            Table = "main";
            Priority = 100;
          }
          # Use main table for everything except the default route
          {
            Table = "main";
            SuppressPrefixLength = 0;
            Priority = 200;
          }
          {
            Table = 1000;
            Priority = 300;
          }
        ];
        routes = [
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "0.0.0.0/0";
            Table = 1000;
          }
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "172.16.16.0/24";
          }
          {
            Gateway = "172.16.16.1";
            GatewayOnLink = true;
            Destination = "10.42.0.0/24";
            # Above DHCP, so a real LAN attachment wins over the tunnel
            Metric = 2048;
          }
          {
            Gateway = "fd42:42:42:3::1";
            GatewayOnLink = true;
            Destination = "fd42:42:42:1::/64";
            Metric = 2048;
          }
          {
            Gateway = "fd42:42:42:3::1";
            GatewayOnLink = true;
            Destination = "fd42:42:42:3::/64";
          }
        ];
        dns = [ "10.42.0.1" ];
        domains = [ "~coditon.com" ];
      };
    };
  };
}
