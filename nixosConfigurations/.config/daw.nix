{ pkgs, ... }:

{
  # Symlink plugin directories to /etc/audio
  environment.etc = {
    "audio/clap".source = "/run/current-system/sw/lib/clap";
    "audio/dssi".source = "/run/current-system/sw/lib/dssi";
    "audio/ladspa".source = "/run/current-system/sw/lib/ladspa";
    "audio/lv2".source = "/run/current-system/sw/lib/lv2";
    "audio/lxvst".source = "/run/current-system/sw/lib/lxvst";
    "audio/vst".source = "/run/current-system/sw/lib/vst";
    "audio/vst3".source = "/run/current-system/sw/lib/vst3";
    "audio/soundfonts".source = pkgs.symlinkJoin {
      name = "soundfonts";
      paths = [
        "${pkgs.soundfont-fluid}/share/soundfonts"
        "${pkgs.soundfont-ydp-grand}/share/soundfonts"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    # DAW
    zrythm

    # Guitar/bass amp simulation
    guitarix
    gxplugins-lv2

    # Synths
    vital
    surge-XT

    # Effects
    # lsp-plugins
    # dragonfly-reverb

    # Drums
    drumkv1

    # MIDI/audio routing
    alsa-utils
    qpwgraph
  ];
}
