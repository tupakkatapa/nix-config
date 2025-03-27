{ lib, ... }:

rec {
  # Parse workspace range like "1-5,7,9-10" into a list of integers
  parseWorkspaceRange = range:
    let
      parts = lib.strings.splitString "," range;

      expandRange = part:
        if lib.strings.hasInfix "-" part then
          let
            endpoints = lib.strings.splitString "-" part;
            start = lib.toInt (builtins.elemAt endpoints 0);
            end = lib.toInt (builtins.elemAt endpoints 1);
          in
          lib.lists.range start end
        else
          [ (lib.toInt part) ];
    in
    builtins.concatMap expandRange parts;

  # Generate monitor configurations from a list of monitor specs
  generateMonitors = monitors:
    let
      calculatePositionX = monitor:
        let
          baseX =
            if monitor.position == 0 then 0
            else if monitor.position > 0 then
              let
                previousMonitors = builtins.filter (m: m.position == (monitor.position - 1)) monitors;
                prevMonitor =
                  if builtins.length previousMonitors > 0
                  then builtins.head previousMonitors
                  else null;
              in
              if prevMonitor != null then
                let
                  modeParts = lib.strings.splitString "x" prevMonitor.mode;
                  prevWidth = lib.toInt (builtins.head modeParts);
                in
                prevWidth
              else 0
            else
              let
                previousMonitors = builtins.filter (m: m.position == (monitor.position + 1)) monitors;
                prevMonitor =
                  if builtins.length previousMonitors > 0
                  then builtins.head previousMonitors
                  else null;
              in
              if prevMonitor != null then
                let
                  modeParts = lib.strings.splitString "x" monitor.mode;
                  width = lib.toInt (builtins.head modeParts);
                in
                  -width
              else 0;
        in
        baseX;
    in
    map
      (monitor:
        let
          position =
            if monitor.position == null then "auto"
            else "${toString (calculatePositionX monitor)}x0";
        in
        "${monitor.name}, ${monitor.mode}, ${position}, 1"
      )
      monitors;

  # Generate workspace configurations from monitor specs
  generateWorkspaces = monitors:
    let
      monitorWorkspacePairs = builtins.concatMap
        (monitor:
          let
            workspaceNumbers = parseWorkspaceRange monitor.workspaces;
          in
          map (wsNum: { inherit monitor wsNum; }) workspaceNumbers
        )
        monitors;

      workspaceConfigs = map
        (pair:
          let
            isPrimary = pair.monitor.primary or false;
            wsNum = toString pair.wsNum;
            extras = if (isPrimary && pair.wsNum == 1) then ", persistent:true, default:true" else "";
          in
          "${wsNum}, monitor:${pair.monitor.name}${extras}"
        )
        monitorWorkspacePairs;
    in
    workspaceConfigs;

  # Generate workspace bindings for standard 1-9,0 layout
  generateWorkspaceBindings = { mod, moveSilent ? "SHIFT", move ? "CTRL" }:
    let
      keyToWorkspace = {
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
        "0" = "10";
      };

      createBindings = key: wsNum: [
        "${mod}, ${key}, workspace, ${wsNum}"
        "${mod} ${moveSilent}, ${key}, movetoworkspacesilent, ${wsNum}"
        "${mod} ${move}, ${key}, movetoworkspace, ${wsNum}"
      ];
    in
    lib.concatLists (lib.mapAttrsToList createBindings keyToWorkspace);
}
