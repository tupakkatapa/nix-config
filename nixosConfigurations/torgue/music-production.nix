{ pkgs
, ...
}: {
  # Music production
  environment.systemPackages = with pkgs; [
    # ardour
    audacity
    guitarix
    gxplugins-lv2
    ladspaPlugins
    qjackctl
    # tuxguitar
  ];
}






