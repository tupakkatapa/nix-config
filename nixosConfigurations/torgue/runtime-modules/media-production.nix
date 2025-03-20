{ pkgs
, ...
}: {
  # Media creation and editing
  environment.systemPackages = with pkgs; [
    aseprite
    gimp
    kdenlive
    video-trimmer
  ];
}







