{ pkgs, ... }:
let
  ps = "${pkgs.procps}/bin/ps";
  grep = "${pkgs.gnugrep}/bin/grep";
  awk = "${pkgs.gawk}/bin/awk";
  xargs = "${pkgs.findutils}/bin/xargs";
  kill = "${pkgs.util-linux}/bin/kill";
  mcp-pattern = "node.*(context7-mcp|claude-mem.*mcp-server)";
  max-age = "7200"; # 2 hours

  script = pkgs.writeShellScript "claude-cleanup" ''
    # Kill orphaned subagents (ppid=1, any age)
    ${ps} -eo pid,ppid,args | \
      ${grep} 'stream-json' | \
      ${awk} '$2 == 1 {print $1}' | \
      ${xargs} -r ${kill} -9 || true

    # Kill any subagent older than ${max-age}s
    ${ps} -eo pid,etimes,args | \
      ${grep} 'stream-json' | \
      ${grep} -v ${grep} | \
      ${awk} '$2 > ${max-age} {print $1}' | \
      ${xargs} -r ${kill} -9 || true

    # Kill orphaned MCP servers (ppid=1, any age)
    ${ps} -eo pid,ppid,args | \
      ${grep} -E '${mcp-pattern}' | \
      ${grep} -v ${grep} | \
      ${awk} '$2 == 1 {print $1}' | \
      ${xargs} -r ${kill} || true

    # Kill detached MCP servers older than ${max-age}s (subagent MCPs)
    # Orchestrator MCPs run on a tty and are excluded
    ${ps} -eo pid,tty,etimes,args | \
      ${grep} -E '${mcp-pattern}' | \
      ${grep} -v ${grep} | \
      ${awk} '$2 == "?" && $3 > ${max-age} {print $1}' | \
      ${xargs} -r ${kill} || true
  '';
in
{
  systemd.user.services.claude-cleanup = {
    Unit.Description = "Kill orphaned Claude Code subagents and MCP servers";
    Service = {
      Type = "oneshot";
      ExecStart = "${script}";
    };
  };
  systemd.user.timers.claude-cleanup = {
    Unit.Description = "Periodic cleanup of orphaned Claude subagents";
    Timer = {
      OnBootSec = "15m";
      OnUnitActiveSec = "15m";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
