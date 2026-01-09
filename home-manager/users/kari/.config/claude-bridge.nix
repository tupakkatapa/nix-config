{ pkgs
, ...
}:
let
  claude-bridge = pkgs.callPackage ../../../../packages/claude-bridge { };
in
{
  # Claude-bridge: local HTTP server for browser-to-Claude integration
  # Bookmarklets in Firefox call this server to summarize/extract from pages

  home.packages = [ claude-bridge ];

  systemd.user.services.claude-bridge = {
    Unit = {
      Description = "Claude Bridge - Browser to Claude integration server";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${claude-bridge}/bin/claude-bridge";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "CLAUDE_BRIDGE_PORT=8787"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
