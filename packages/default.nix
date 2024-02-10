{pkgs}: rec {
  "monitor-adjust" = pkgs.callPackage ./monitor-adjust {};
  "ping-sweep" = pkgs.callPackage ./ping-sweep {};
  "print-banner" = pkgs.callPackage ./print-banner {};
  "fissh" = pkgs.callPackage ./fissh {};
  "pipewire-out-switcher" = pkgs.callPackage ./pipewire-out-switcher {};
  # Wofi scripts
  "dm-pipewire-out-switcher" = pkgs.callPackage ./wofi-scripts/dm-pipewire-out-switcher {};
  "dm-quickfile" = pkgs.callPackage ./wofi-scripts/dm-quickfile {};
  "dm-radio" = pkgs.callPackage ./wofi-scripts/dm-radio {};
  # Notify scripts
  "notify-screenshot" = pkgs.callPackage ./notify-scripts/notify-screenshot {};
  "notify-volume" = pkgs.callPackage ./notify-scripts/notify-volume {};
  "notify-pipewire-out-switcher" = pkgs.callPackage ./notify-scripts/notify-pipewire-out-switcher {};
  "notify-not-hyprprop" = pkgs.callPackage ./notify-scripts/notify-not-hyprprop {};
}
