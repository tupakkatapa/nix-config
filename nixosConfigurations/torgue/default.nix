{ pkgs
, ...
}: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B root@torgue";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    ../.config/hw/cpu-intel.nix
    ../.config/hw/gpu-intel.nix
    ../.config/keyd.nix
    ../.config/hw/pipewire.nix
    ../.config/nix-ld.nix
    ../.config/tuigreet-hypr.nix
    ../.config/hw/yubikey.nix
    ./persistence.nix
  ];

  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:/mnt/sftp/code/workspace/tupakkatapa/nix-config";
    builtinModules.enable = true;
    modules = [
      {
        name = "auto-scrcpy";
        imports = [ ../.config/auto-scrcpy.nix ];
      }
      {
        name = "plexamp";
        imports = [{
          environment.systemPackages = with pkgs; [
            plexamp
          ];
        }];
      }
    ];
  };

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # NTFS support
  boot.supportedFilesystems = [ "ntfs" ];
  environment.systemPackages = [ pkgs.ntfs3g ];

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # Connectivity
  networking = {
    hostName = "torgue";
    firewall = {
      enable = true;
      interfaces."enp0s31f6".allowedTCPPorts = [ 9100 ];
    };
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    links."10-wol" = {
      matchConfig.MACAddress = "30:9c:23:3c:b9:01";
      linkConfig = {
        NamePolicy = "kernel database onboard slot path";
        WakeOnLan = "magic";
      };
    };
    networks."10-wan" = {
      linkConfig.RequiredForOnline = "routable";
      matchConfig.Name = [ "enp0s31f6" ];
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        # Stays the default DNS route despite its route-only domain
        DNSDefaultRoute = true;
      };
      dhcpV6Config.DUIDType = "link-layer";
      # Resolves outside the tunnel it brings up
      domains = [ "~vpn.coditon.com" ];
    };
  };

  # Monitoring + central log shipping
  services.monitoring = {
    enable = true;
    openFirewall = false;
  };

  # Service account for remote management
  users.users.service = {
    isSystemUser = true;
    group = "service";
    shell = "/bin/sh";
    openssh.authorizedKeys.keys = [
      ''command="sudo systemctl poweroff",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICne6AlhwNtQ6/whwnSdPUGQge3lRzebrk+ahd7qqn7W hass@vladof''
    ];
  };
  users.groups.service = { };
  security.sudo.extraRules = [{
    users = [ "service" ];
    commands = [{
      command = "/run/current-system/sw/bin/systemctl poweroff";
      options = [ "NOPASSWD" ];
    }];
  }];
}
