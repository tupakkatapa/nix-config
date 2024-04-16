_: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    #alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Make pipewire realtime-capable
  security.rtkit.enable = true;
}
