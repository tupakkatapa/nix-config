_: {
  # Disable CPU security mitigations for performance
  boot.kernelParams = [
    "mitigations=off"
    "l1tf=off"
    "mds=off"
    "no_stf_barrier"
    "noibpb"
    "noibrs"
    "nopti"
    "nospec_store_bypass_disable"
    "nospectre_v1"
    "nospectre_v2"
    "tsx=on"
    "tsx_async_abort=off"
  ];

  # Xbox controllers
  hardware.xpadneo.enable = true;
  hardware.xone.enable = true;
}
