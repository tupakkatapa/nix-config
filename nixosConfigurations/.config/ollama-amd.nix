{ lib, ... }: {
  # GPU compute support for ROCm
  hardware.amdgpu.opencl.enable = true;
  hardware.graphics.enable = true;

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    # RX 6700 is gfx1031, override to supported gfx1030
    rocmOverrideGfx = "10.3.0";
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "-1";
    };
    loadModels = [
      # https://ollama.com/library
      "huihui_ai/qwen3.5-abliterated:9b"
      "qwen3.5:9b"
    ];
  };

  # Fix GPU detection race on boot
  systemd.services.ollama = {
    wants = [ "modprobe@amdgpu.service" ];
    after = [ "modprobe@amdgpu.service" ];
  };

  # ROCm needs JIT compilation of GPU kernels (writable+executable memory)
  # Without this, runner subprocesses timeout during GPU discovery after model unload
  systemd.services.ollama.serviceConfig.MemoryDenyWriteExecute = lib.mkForce false;
}
