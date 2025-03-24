{ pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    aseprite
    gimp
    kdenlive
    video-trimmer
  ];
}










