_: {
  boot.kernelParams = [
    # Enable clock and voltage adjustment
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  # I2C for hardware communication (RGB, sensors)
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];
}
