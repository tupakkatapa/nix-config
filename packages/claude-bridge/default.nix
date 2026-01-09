{ pkgs
, lib
}:
let
  # yt-subs helper script
  yt-subs = pkgs.writeShellScriptBin "yt-subs" ''
    if [ $# -eq 0 ]; then
      echo "Usage: yt-subs <youtube_url>" >&2
      exit 1
    fi
    d=$(mktemp -d)
    trap 'rm -rf "$d"' EXIT
    ${pkgs.yt-dlp}/bin/yt-dlp -q --skip-download --write-auto-sub -o "$d/s" "$1" 2>/dev/null
    ${pkgs.gnugrep}/bin/grep -vE '^WEBVTT|^Kind:|^Language:|^[0-9]|^$' "$d"/*.vtt 2>/dev/null | ${pkgs.gnused}/bin/sed 's/<[^>]*>//g' || true
  '';

  runtimeDeps = [
    pkgs.html2text
    pkgs.shot-scraper
    yt-subs
  ];
in
pkgs.rustPlatform.buildRustPackage {
  pname = "claude-bridge";
  version = "0.1.0";
  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/claude-bridge \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';

  meta = {
    description = "Local HTTP server for browser-to-Claude integration";
    license = lib.licenses.mit;
    mainProgram = "claude-bridge";
  };
}
