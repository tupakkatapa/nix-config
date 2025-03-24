{ pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    ardour
    audacity
    guitarix
    gxplugins-lv2
    ladspaPlugins
    qjackctl
    tuxguitar
  ];

  # Real-time audio
  musnix.enable = true;
}
