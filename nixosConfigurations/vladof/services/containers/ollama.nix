{ lib
, dataDir
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.ollama.uid;
in
{
  containers.ollama = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.ollama) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/ollama" = {
        hostPath = "${dataDir}/home/ollama/appdata/ollama";
        isReadOnly = false;
      };
    };

    config = { pkgs, ... }: (globalContainerConfig "ollama") // {
      services.ollama = {
        enable = true;
        package = pkgs.ollama;
        openFirewall = true;
        inherit (containerConfig.ollama) port;
        host = "0.0.0.0";
        acceleration = false;
        loadModels = [
          # https://ollama.com/library
          "dolphin-mixtral:8x7b"
          "llama3.2:3b"
        ];
      };

      # Disable DynamicUser to work with bind-mounted state directory
      systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;
    };
  };

  # Ensure host directories for the bind mount exist
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/ollama/appdata/ollama/models 755 ${uid} ${uid} -"
  ];
}
