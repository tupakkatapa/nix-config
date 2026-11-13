{ pkgs, ... }:
let
  # Queues the audio of a YouTube URL, or of the first search hit, into MPD
  mpc-yt = pkgs.writeShellApplication {
    name = "mpc-yt";
    runtimeInputs = [ pkgs.yt-dlp pkgs.mpc ];
    text = ''
      query="$*"
      case "$query" in
        http://* | https://*) ;;
        *) query="ytsearch1:$query" ;;
      esac
      yt-dlp --no-playlist -f bestaudio --print title --print urls "$query" | {
        read -r title
        read -r url
        mpc -q add "$url"
        echo "Queued: $title"
      }
    '';
  };
in
{
  # MPD plays the library into Snapcast, which streams it to the snapclients on the network
  services.mpd = {
    enable = true;
    openFirewall = false;
    settings = {
      music_directory = "/mnt/wd-red/sftp/media/music";
      bind_to_address = "127.0.0.1";
      audio_output = [{
        type = "pipe";
        name = "Snapcast";
        command = "${pkgs.socat}/bin/socat -u - TCP:127.0.0.1:4953";
        format = "48000:16:2";
        mixer_type = "software";
      }];
    };
  };

  # The database lives on the ephemeral root, so it is rebuilt at every start
  systemd.services.mpd.postStart = "${pkgs.mpc}/bin/mpc -q update";

  services.snapserver = {
    enable = true;
    settings = {
      stream.source = "tcp://127.0.0.1:4953?name=mpd&mode=server&sampleformat=48000:16:2";
      # Control stays local, for Home Assistant
      tcp-control = {
        enabled = true;
        bind_to_address = "127.0.0.1";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 1704 ];

  # Static user for the module's DynamicUser, which base.nix disables
  users.users.snapserver = { isSystemUser = true; group = "snapserver"; };
  users.groups.snapserver = { };

  environment.systemPackages = [ pkgs.mpc pkgs.yt-dlp mpc-yt ];
}
