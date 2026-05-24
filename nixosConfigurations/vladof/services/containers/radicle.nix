# Radicle seed node + httpd in nspawn container.
#
# Two public ports: 8776 (seed) + 8788 (httpd, behind caddy).
# Secrets are decrypted on the host by agenix and bind-mounted into the
# container.
#
# Bootstrap (one-time): on any host with radicle-node available, generate
# the keypair under a throwaway RAD_HOME, then encrypt with agenix:
#
#   nix run nixpkgs#radicle-node -- auth --alias seed-vladof
#   nix develop -c agenix edit nixosConfigurations/vladof/secrets/radicle-private-key.age
#   nix develop -c agenix edit nixosConfigurations/vladof/secrets/radicle-passphrase.age
#   nix develop -c agenix rekey -a
#
# Then paste the public key into services.radicle.publicKey below.
{ config
, dataDir
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.radicle.uid;
  seedPort = 8776;
in
{
  containers.radicle = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.radicle) hostAddress localAddress;

    bindMounts = {
      "/var/lib/radicle" = {
        hostPath = "${dataDir}/home/radicle/appdata/radicle";
        isReadOnly = false;
      };
      "/run/secrets/radicle-private-key" = {
        hostPath = config.age.secrets.radicle-private-key.path;
        isReadOnly = true;
      };
      "/run/secrets/radicle-passphrase" = {
        hostPath = config.age.secrets.radicle-passphrase.path;
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "radicle") // {
      services.radicle = {
        enable = true;
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTXgqT8CnP/mAVTwVKoMgnuFtBWWh20MRYb+coof3xr";
        # Plain path (no `name:`) → module uses LoadCredential (raw file copy).
        # A `name:path` form triggers LoadCredentialEncrypted, which expects
        # systemd-creds-encrypted content and would fail on agenix plaintext.
        privateKeyFile = "/run/secrets/radicle-private-key";

        node = {
          openFirewall = true;
          listenAddress = "0.0.0.0";
          listenPort = seedPort;
        };

        httpd = {
          enable = true;
          listenAddress = "0.0.0.0";
          listenPort = containerConfig.radicle.port;
        };

        # rad won't accept a partial config: we must include the full default
        # schema and only override fields we care about. Generated via
        # `rad config init` in nixpkgs#radicle-node.
        settings = {
          publicExplorer = "https://app.radicle.xyz/nodes/$host/$rid$path";
          preferredSeeds = [ ];
          web.pinned.repositories = [ ];
          cli.hints = true;
          node = {
            alias = "seed-vladof";
            listen = [ ];
            peers.type = "dynamic";
            connect = [ ];
            externalAddresses = [ ];
            network = "main";
            log = "INFO";
            relay = "always";
            workers = 8;
            seedingPolicy = {
              default = "allow";
              scope = "all";
            };
            limits = {
              routingMaxSize = 1000;
              routingMaxAge = 604800;
              gossipMaxAge = 1209600;
              fetchConcurrency = 1;
              maxOpenFiles = 4096;
              rate = {
                inbound = { fillRate = 5.0; capacity = 1024; };
                outbound = { fillRate = 10.0; capacity = 2048; };
              };
              connection = { inbound = 128; outbound = 16; };
              fetchPackReceive = "500.0 MiB";
            };
          };
        };
      };

      # radicle-node reads RAD_PASSPHRASE to decrypt the SSH key without
      # prompting. Secret file must be in env-file format: `RAD_PASSPHRASE=...`
      systemd.services.radicle-node.serviceConfig.EnvironmentFile = "/run/secrets/radicle-passphrase";

      networking.firewall.allowedTCPPorts = [ seedPort containerConfig.radicle.port ];
    };
  };

  # Open the seed port on the host's external firewall.
  networking.firewall.allowedTCPPorts = [ seedPort ];

  # Forward public seed port (8776) to the container, mirroring the
  # PREROUTING rules generated in containers/default.nix for the httpd port.
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp -d 10.42.0.8 --dport ${toString seedPort} -j DNAT --to-destination ${containerConfig.radicle.localAddress}:${toString seedPort}
    iptables -t nat -A PREROUTING -p tcp -d 172.16.16.1 --dport ${toString seedPort} -j DNAT --to-destination ${containerConfig.radicle.localAddress}:${toString seedPort}
    iptables -A FORWARD -p tcp -d ${containerConfig.radicle.localAddress} --dport ${toString seedPort} -j ACCEPT
  '';

  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/radicle/appdata/radicle 0750 ${uid} ${uid} -"
    "Z ${dataDir}/home/radicle/appdata/radicle - ${uid} ${uid} -"
  ];

  age.secrets = {
    radicle-private-key = {
      rekeyFile = ../../secrets/radicle-private-key.age;
      mode = "0400";
    };
    radicle-passphrase = {
      rekeyFile = ../../secrets/radicle-passphrase.age;
      mode = "0400";
    };
  };
}
