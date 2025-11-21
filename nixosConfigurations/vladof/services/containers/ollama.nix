{ dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
{
  containers.ollama = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.ollama) hostAddress localAddress;

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
        inherit (servicesConfig.ollama) port;
        host = "0.0.0.0";
        acceleration = false;
        loadModels = [
          # https://ollama.com/library
          "dolphin-mixtral:8x7b"
          "llama3.2:3b"
        ];
      };
    };
  };
}


