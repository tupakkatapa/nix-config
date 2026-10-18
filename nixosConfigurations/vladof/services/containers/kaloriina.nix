{ dataDir
, containerConfig
, globalContainerConfig
, inputs
, ...
}:
let
  cfg = containerConfig.kaloriina;
  uid = builtins.toString cfg.uid;
in
{
  containers.kaloriina = {
    autoStart = true;
    privateNetwork = true;
    inherit (cfg) hostAddress localAddress;

    # The SQLite database lives on the host.
    bindMounts."/var/lib/kaloriina" = {
      hostPath = "${dataDir}/home/kaloriina/appdata";
      isReadOnly = false;
    };

    config = { pkgs, ... }: {
      imports = [
        (globalContainerConfig "kaloriina")
        inputs.kaloriina.nixosModules.default
      ];

      services.kaloriina = {
        enable = true;
        package = inputs.kaloriina.packages.${pkgs.stdenv.hostPlatform.system}.default;
        # Listens on the container's own address for Caddy on the host.
        address = cfg.localAddress;
        inherit (cfg) port;
        allowedHosts = [ cfg.addr ];
        openFirewall = true;
        # Readings from the scale land on the local day.
        timeZone = "Europe/Helsinki";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/kaloriina/appdata 750 ${uid} ${uid} -"
    "Z ${dataDir}/home/kaloriina/appdata - ${uid} ${uid} -"
  ];
}
