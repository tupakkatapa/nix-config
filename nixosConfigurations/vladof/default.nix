{ pkgs
, lib
, config
, inputs
, unstable
, outputs
, ...
}:
let
  domain = "coditon.com";
  user = "kari";
  dataDir = "/mnt/wd-red";

  # Inherit global stuff for imports
  extendedArgs = { inherit pkgs lib config domain dataDir inputs unstable; };
in
{
  # openrgb 1.0rc2+ (26.05, still broken in 1.0rc3.1) regressed the client
  # `-z`/`--size` CLI parser (any `-z` -> "Invalid option"), so the Corsair zone
  # sizes can't be set and its LEDs stay dark. Pin openrgb to 25.11's 0.9
  # (server + client) until fixed.
  nixpkgs.overlays = [
    (_: prev: { openrgb = inputs.nixpkgs-2511.legacyPackages.${prev.stdenv.hostPlatform.system}.openrgb; })
  ];

  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w root@vladof";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  # Bluetooth pairing keys; re-pairing a device needs a re-export
  age.secrets.bt-galaxy-buds4-pro = {
    rekeyFile = ./secrets/bt-galaxy-buds4-pro.age;
    path = "/var/lib/bluetooth/BC:09:1B:26:19:8D/78:C1:1D:EA:46:EF/info";
    symlink = false;
  };
  age.secrets.bt-mx-master-2s = {
    rekeyFile = ./secrets/bt-mx-master-2s.age;
    path = "/var/lib/bluetooth/BC:09:1B:26:19:8D/CC:47:F4:B7:4B:AF/info";
    symlink = false;
  };

  imports = [
    (import ./services extendedArgs)
    (import ./persistence.nix extendedArgs)
    ../.config/hw/bluetooth.nix
    ../.config/hw/cpu-amd.nix
    ../.config/hw/gpu-amd.nix
    ../.config/hw/gamepad.nix
    ../.config/motd.nix
    ../.config/hw/pipewire.nix
    ../.config/hw/yubikey.nix
    ../.config/nix-ld.nix
    ../.config/podman.nix
  ];

  services.runtimeModules = {
    enable = true;
    # Only pushed commits; the workspace is writable by everything in the sftp group
    flakeUrl = "github:tupakkatapa/nix-config";
    builtinModules.enable = true;
    modules = [
      {
        name = "retroarch";
        imports = [ (import ../.config/retroarch.nix (extendedArgs // { share = "${dataDir}/sftp/appdata/retroarch"; })) ];
      }
      {
        name = "steam";
        imports = [ "${inputs.runtime-modules}/nixosModules/rt-modules/steam.nix" ];
      }
      {
        name = "plexamp";
        imports = [{ environment.systemPackages = [ pkgs.plexamp ]; }];
      }
    ];
  };

  # The couch session enables these without a password. Hooks would run as
  # root under sudo, so the session starts the apps itself afterwards.
  security.sudo.extraRules = [{
    users = [ "kari" ];
    commands = map
      (module: { command = "/run/current-system/sw/bin/runtime-modules -f enable ${module}"; options = [ "NOPASSWD" ]; })
      [ "retroarch" "steam" "plexamp" ];
  }];

  # Overrides the graphical-desktop default set (CJK, unifont, emoji)
  fonts.enableDefaultPackages = false;
  fonts.packages = [ pkgs.dejavu_fonts pkgs.liberation_ttf ];

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # Remote builder for the desktops; the forced command keeps their host keys to the store protocol
  users.users.nixremote = {
    isSystemUser = true;
    group = "nixremote";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = map
      (host: ''command="${config.nix.package}/bin/nix-daemon --stdio",restrict ${outputs.nixosConfigurations.${host}.config.age.rekey.hostPubkey}'')
      [ "maliwan" ];
  };
  users.groups.nixremote = { };
  nix.settings.trusted-users = [ "nixremote" ];

  # Couch desktop on the TV: autologin into sway
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "sway";
      inherit user;
    };
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    server.port = 6742;
  };

  # Apply colors after server is ready (client mode)
  systemd.services.openrgb-colors = {
    description = "Apply OpenRGB colors";
    after = [ "openrgb.service" ];
    requires = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      StartLimitIntervalSec = 90;
      StartLimitBurst = 10;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Devices (esp. the Corsair USB HID) enumerate after the server socket is
      # up, so early runs hit "Invalid device ID"; retry until they appear.
      Restart = "on-failure";
      RestartSec = 5;
    };
    path = [ pkgs.openrgb ];
    script = ''
      # Set Corsair zone sizes (resets on power cycle)
      openrgb --client -d 1 -z 0 --mode static --size 30 --color 000000
      openrgb --client -d 1 -z 1 --mode static --size 30 --color 000000
      # Apply colors (Corsair at 50% brightness: 850255->43012B, 330066->1A0033)
      openrgb --client -d 0 --mode static --color 330066
      openrgb --client -d 1 -z 0 --mode direct --color 43012B
      openrgb --client -d 1 -z 1 --mode direct --color 1A0033
    '';
  };

  # SFTP server: chrooted sftp user under ${dataDir}/sftp
  services.openssh = {
    allowSFTP = true;
    extraConfig = ''
      Match User sftp
        AllowAgentForwarding no
        AllowTcpForwarding no
        ChrootDirectory %h
        ForceCommand internal-sftp -u 0002
        PermitTunnel no
        X11Forwarding no
      Match all
    '';
  };

  # WebP and AVIF saved by clients' Firefox; transmission's files may still be seeding
  systemd.paths.webp-convert = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "${dataDir}/sftp/dnld";
  };
  systemd.services.webp-convert = {
    description = "Convert downloaded WebP and AVIF images to JPEG or PNG";
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      User = "sftp";
      Group = "sftp";
    };
    script = "${pkgs.findutils}/bin/find ${dataDir}/sftp/dnld -maxdepth 1 -type f \\( -iname '*.webp' -o -iname '*.avif' \\) -user sftp -exec ${pkgs.webp-convert}/bin/webp-convert {} +";
  };

  users.users.sftp = {
    isSystemUser = true;
    useDefaultShell = false;
    group = "sftp";
    extraGroups = [ "sshd" "transmission" ];
    home = "${dataDir}/sftp";
    openssh.authorizedKeys.keys = [
      # kari@phone (preferably removed, keep until YubiKey NFC for SFTP is possible)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@boox
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOliW+jvO3gMcZdwGvaSNlqcA3BWDWL+PM3omgXyWSHZ kari@boox"

      # kari@trezor
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPSvwAIfx+2EYVbr9eC2imb5NJgpn36v6XAeofQjg5BEAAAABHNzaDo= kari@trezor"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOcS3prYIi5uC9LxscaKSYzyuF2Sh7f3I5V9s1sCWSc1AAAACXNzaDprYXJpMg== ssh:kari2"
    ];
  };
  users.groups.sftp = { };

  # Connectivity
  networking = {
    hostName = "vladof";
    domain = "${domain}";
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    links."10-wol" = {
      matchConfig.MACAddress = "d4:5d:64:d1:12:52";
      linkConfig = {
        NamePolicy = "kernel database onboard slot path";
        WakeOnLan = "magic";
      };
    };
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "enp4s0" ];
        # SNAT source for searx container, below DHCP pool (see containers/searx.nix).
        # /32 so it adds no prefix route; host LAN traffic keeps sourcing from the lease.
        address = [ "10.42.0.28/32" ];
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV6Config.DUIDType = "link-layer";
      };
    };
  };

}
