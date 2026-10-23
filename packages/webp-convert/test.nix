{ pkgs
, webp-convert
}:
pkgs.runCommand "webp-convert-test" { nativeBuildInputs = [ webp-convert pkgs.imagemagick pkgs.file ]; } ''
  set -euo pipefail
  cd "$(mktemp -d)"
  mime() { file -b --mime-type "$1"; }

  magick -size 16x16 plasma: -quality 80 lossy.webp
  magick -size 16x16 xc:none -fill red -draw "circle 8,8 8,2" -quality 80 alpha.webp
  magick -size 16x16 xc:blue -define webp:lossless=true lossless.webp
  magick -delay 10 -size 16x16 xc:red xc:blue -loop 0 animated.webp
  magick -size 16x16 plasma: -quality 80 "with space.WEBP"
  magick -size 16x16 plasma: -quality 80 clash.webp
  echo existing >clash.jpg
  touch empty.webp
  echo text >fake.webp

  status=0
  webp-convert . >out || status=$?

  [[ $(mime lossy.jpg) == image/jpeg ]]
  [[ $(mime alpha.png) == image/png ]]
  [[ $(mime lossless.png) == image/png ]]
  [[ $(mime "with space.jpg") == image/jpeg ]]
  [[ -e animated.webp && ! -e animated.png && ! -e animated.jpg ]]
  [[ $(cat clash.jpg) == existing ]]
  [[ $(mime clash-1.jpg) == image/jpeg ]]
  [[ -e empty.webp && ! -e empty.png && ! -e empty.jpg ]]
  [[ -e fake.webp && ! -e fake.png && ! -e fake.jpg ]]
  [[ ! -e lossy.webp && ! -e clash.webp ]]
  [[ $status == 1 ]]
  grep -qx './lossy.jpg' out

  touch $out
''
