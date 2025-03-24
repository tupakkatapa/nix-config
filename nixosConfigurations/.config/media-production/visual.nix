{ pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    aseprite
    gimp
    kdePackages.kdenlive
    video-trimmer
  ];
}
