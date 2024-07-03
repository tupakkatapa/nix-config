{ pkgs
, ...
}: {
  systemd.services.openrgb = {
    description = "OpenRGB Daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.openrgb}/bin/openrgb --server";
      Restart = "on-failure";
    };
  };
  services.udev.packages = [ pkgs.openrgb-with-all-plugins ];
  # You must load the i2c-dev module along with the correct i2c driver for your motherboard.
  # This is usually i2c-piix4 for AMD systems and i2c-i801 for Intel systems.
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

  # CLI/GUI program
  environment.systemPackages = with pkgs; [
    openrgb-with-all-plugins
  ];
}
