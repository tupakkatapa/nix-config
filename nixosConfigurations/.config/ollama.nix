{ pkgs, ... }: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    openFirewall = false;
    port = 11434;
    acceleration = "rocm";
    loadModels = [
      # https://ollama.com/library
      "deepseek-coder-v2:16b"
      "deepseek-r1:32b"
    ];
    home = "/var/lib/ollama";
  };

  services.open-webui = {
    enable = true;
    openFirewall = false;
    port = 11444;
    host = "127.0.0.1";
    environment = {
      WEBUI_AUTH = "False";
      OLLAMA_API_BASE_URL = "http://localhost:11434";
    };
  };
}
