{ pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD, Broadwell+
      intel-vaapi-driver # i965, pre-Broadwell fallback
    ];
  };

  # iHD is the modern driver; libva otherwise probes i965 first
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
