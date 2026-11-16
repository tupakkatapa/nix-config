{ config
, osConfig
, lib
, pkgs
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT TERMINAL THEME;
  colors = customLib.colors.${THEME};
  swayosd = "${config.services.swayosd.package}/bin/swayosd-client";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  mascot = name: colour: pkgs.runCommand name { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${./claude-mascot.py} $out ${colour}
    python3 -c 'import struct, sys; d = open(sys.argv[1], "rb").read(24); assert d[:8] == b"\x89PNG\r\n\x1a\n" and struct.unpack(">II", d[16:24]) == (512, 512)' $out
  '';

  # Runtime-module apps get installed (green), building (yellow) and missing (red) variants
  icons = pkgs.runCommand "couch-menu-icons" { nativeBuildInputs = [ pkgs.librsvg pkgs.imagemagick ]; } ''
    mkdir $out
    for icon in firefox retroarch steam plexamp; do
      rsvg-convert -w 192 -h 192 ${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/$icon.svg -o $out/$icon.png
    done
    for icon in retroarch steam plexamp; do
      dot() { magick $out/$icon.png -fill "#$1" -stroke "#${colors.base00}" -strokewidth 8 -draw "circle 158,158 158,182" "$2"; }
      dot ${colors.base0B} $out/$icon-on.png
      dot ${colors.base0A} $out/$icon-busy.png
      dot ${colors.base08} $out/$icon-off.png
    done
  '';

  couchPad = pkgs.writers.writePython3 "couch-pad"
    { libraries = [ pkgs.python3Packages.evdev pkgs.python3Packages.i3ipc ]; }
    (builtins.readFile ./couch-pad.py);

  # GtkLayerShell comes through GObject introspection, which the Python
  # wrapper leaves out
  couchOsk = pkgs.writers.writePython3 "couch-osk"
    {
      libraries = [ pkgs.python3Packages.pygobject3 ];
      makeWrapperArgs = [ "--prefix" "GI_TYPELIB_PATH" ":" (lib.makeSearchPathOutput "out" "lib/girepository-1.0" [ pkgs.gtk3 pkgs.gtk-layer-shell pkgs.pango pkgs.gdk-pixbuf pkgs.harfbuzz pkgs.at-spi2-core pkgs.glib pkgs.gobject-introspection ]) ];
    }
    (builtins.readFile ./couch-osk.py);
  # Styled like the menu
  oskStyle = pkgs.writeText "couch-osk.css" ''
    window { background: transparent; }
    .panel { background: #${colors.base00}; border: 1px solid #${colors.base02}; border-radius: 16px; padding: 12px 12px 8px; box-shadow: 0 12px 32px rgba(0, 0, 0, 0.6); }
    .key { font: 18pt "${FONT}"; color: #${colors.base05}; background: #${colors.base01}; border-radius: 10px; margin: 4px; padding: 10px 16px; }
    .key.shift { color: #${colors.base0A}; }
    .key.selected { color: #${colors.base00}; background: #${colors.base0A}; }
    .hint { font: 11pt "${FONT}"; color: #${colors.base04}; margin-top: 8px; }
  '';

  # Hand-picked sites for the pad's Y, as tiles with their logos (Simple
  # Icons) in brand colour
  sites = [
    { name = "Plex"; url = "https://plex.coditon.com/web"; logo = "plex"; color = "EBAF00"; hash = "sha256-EpUAwr2iF1yVQC0S4KlmQt5holYdRaTZcZ7cir1DyOo="; }
    { name = "YouTube"; url = "https://www.youtube.com/feed/subscriptions"; logo = "youtube"; color = "FF0000"; hash = "sha256-UDiAisu8Tm7doWy+scxt7IDk5O5OIn4DnEEin6Iiqow="; }
    { name = "Netflix"; url = "https://www.netflix.com"; logo = "netflix"; color = "E50914"; hash = "sha256-Z9vElZiL1WZ6Ce1PVuFNtAcKRMenTil7FGwin3D9b24="; }
    { name = "Kick"; url = "https://kick.com"; logo = "kick"; color = "53FC18"; hash = "sha256-72AC4u7a62haI8yryvqXDwS1PxCb+THWxkX8GVeg0TU="; }
    { name = "Twitch"; url = "https://www.twitch.tv"; logo = "twitch"; color = "9146FF"; hash = "sha256-2+J7wCoBuNibYlnKzvMoyfpwuxPCnzjDbrFCGGP28LY="; }
    { name = "Home Assistant"; url = "https://home.coditon.com"; logo = "homeassistant"; color = "18BCF2"; hash = "sha256-/tKUu6KJrWBc1Mqy35jdI59S1A5cuOA8lIfGSaamKVc="; }
  ];
  logo = site: pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/simple-icons/simple-icons/16.37.0/icons/${site.logo}.svg";
    inherit (site) hash;
  };
  tile = site: ''<a href="${site.url}" style="--color: #${site.color}">@${site.logo}@${site.name}</a>'';
  page = pkgs.writeText "start-page.html" ''
    <!doctype html>
    <meta charset="utf-8">
    <title>Start</title>
    <style>
      html { background: #${colors.base00}; color: #${colors.base05}; font: 22px "${FONT}"; }
      body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
      main { display: grid; grid-template-columns: repeat(3, 240px); gap: 24px; }
      a { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 20px; height: 180px; background: #${colors.base01}; border: 1px solid #${colors.base02}; border-radius: 13px; color: inherit; text-decoration: none; }
      a:focus, body:not(.walking) a:hover { background: #${colors.base0A}; color: #${colors.base00}; outline: none; }
      svg { width: 64px; height: 64px; fill: var(--color); }
      a:focus svg, body:not(.walking) a:hover svg { fill: #${colors.base00}; }
    </style>
    <main>${lib.concatMapStrings tile sites}</main>
    <script>
      // The last input chooses. After the d-pad, A (a click wherever the
      // pointer rests) opens the walked-to tile; after the pointer moves, the
      // tile under it. A click may not take the focus off the chosen tile
      const tiles = [...document.querySelectorAll("a")];
      const steps = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -3, ArrowDown: 3 };
      let at = 0, pointer = null;
      const walk = () => { document.body.classList.add("walking"); tiles[at].focus(); };
      walk();
      addEventListener("keydown", event => {
        if (!(event.key in steps)) return;
        at = (at + steps[event.key] + tiles.length) % tiles.length;
        walk();
        event.preventDefault();
      });
      addEventListener("mousemove", event => {
        const now = [event.clientX, event.clientY].join();
        const moved = pointer !== null && pointer !== now;
        pointer = now;
        if (!moved) return;
        document.body.classList.remove("walking");
        tiles[at].blur();
      });
      addEventListener("mousedown", event => event.preventDefault());
      addEventListener("click", event => {
        if (!document.body.classList.contains("walking") || event.target.closest("a") === tiles[at]) return;
        event.preventDefault();
        tiles[at].click();
      });
    </script>
  '';
  # The logos go in as inline SVG, for the CSS to colour them
  startPage = pkgs.runCommand "start-page.html" { } ''
    cp ${page} $out
    ${lib.concatMapStrings (site: ''
      substituteInPlace $out --replace-fail '@${site.logo}@' "$(cat ${logo site})"
    '') sites}
  '';

  couchMenu = pkgs.writeShellApplication {
    name = "couch-menu";
    runtimeInputs = [ pkgs.coreutils pkgs.util-linux pkgs.jq config.wayland.windowManager.sway.package config.programs.fuzzel.package ];
    runtimeEnv = {
      ICONS = icons;
      inherit TERMINAL;
    };
    text = builtins.readFile ./couch-menu.sh;
  };
in
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    ../.config/base01/rice01/cursor.nix
    ../.config/base01/rice01/nixvim.nix
  ];

  home.pointerCursor.size = 32;

  programs.herdr = {
    server.enable = true;
    matrix = {
      enable = true;
      homeserver = "https://matrix.coditon.com";
      owner = "@tupakkatapa:coditon.com";
      displayName = "Claude";
      avatar = mascot "claude-mascot.png" "d77757";
      spawnAvatar = mascot "claude-mascot-blue.png" "4a90d9";
      environmentFile = osConfig.age.secrets.herdr-matrix-env.path;
      # The agent that works here: a plain name in its chat, and `wake` on the hour, whose answer `NOOP` posts nothing
      agents.assistant = {
        cwd = "${config.home.homeDirectory}/Workspace/tupakkatapa/assistant";
        prefix = false;
        prompts.wake = {
          text = "wake";
          onCalendar = "hourly";
        };
      };
      # Reads and sends in the owner's bridged chats for `herdr-matrix chats`, under its own user
      gate = {
        enable = true;
        tokenFile = osConfig.age.secrets.matrix-gate-token.path;
      };
      transcribe = {
        model = {
          url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
          hash = "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
        };
        # Detection mislabels accented English as Finnish
        language = "en";
      };
    };
  };

  # The path of a decrypted secret stays the same; a new token must restart the bot
  systemd.user.services.herdr-matrix.Unit.X-Restart-Triggers = [ (builtins.hashFile "sha256" osConfig.age.secrets.herdr-matrix-env.file) ];

  # Couch launcher on the TV: bare compositor, every window fullscreen
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod1";
      bars = [ ];
      # A window that loses fullscreen to another (only one per workspace)
      # still fills the screen as the only tile
      window = {
        border = 0;
        titlebar = false;
      };
      floating = {
        border = 0;
        titlebar = false;
      };
      output."*" = {
        # 1920x1080 lays out as 1371x771, readable from the couch
        scale = "1.4";
        bg = "#1d2021 solid_color";
      };
      startup = [{ command = lib.getExe couchMenu; }];
      seat."*".xcursor_theme = "\"${config.home.pointerCursor.name}\" ${toString config.home.pointerCursor.size}";
      input."type:keyboard" = {
        xkb_layout = "fi";
        xkb_numlock = "enabled";
      };
      # The pad's stick has its own speed curve
      input."3084:1:Couch_pad".accel_profile = "flat";
      keybindings = {
        "Mod1+Return" = "exec ${lib.getExe couchMenu} --terminal";
        "Mod1+q" = "exec ${lib.getExe couchMenu} --menu";
        "Mod1+Shift+q" = "kill";
        # The menu over whatever is on screen; the pad's Xbox button is Super
        "--release Super_L" = "exec ${lib.getExe couchMenu} --menu";
        "XF86HomePage" = "exec ${lib.getExe couchMenu} --menu";
        "XF86AudioRaiseVolume" = "exec ${swayosd} --output-volume raise";
        "XF86AudioLowerVolume" = "exec ${swayosd} --output-volume lower";
        "XF86AudioMute" = "exec ${swayosd} --output-volume mute-toggle";
        "XF86AudioPlay" = "exec ${playerctl} play-pause";
        "XF86AudioNext" = "exec ${playerctl} next";
        "XF86AudioPrev" = "exec ${playerctl} previous";
      };
      window.commands = [
        { criteria.app_id = ".*"; command = "fullscreen enable"; }
        { criteria.class = ".*"; command = "fullscreen enable"; }
      ];
    };
  };

  # One instance per pad, started by udev as the pad connects, ending as it
  # disconnects
  systemd.user.services."couch-pad@" = {
    Unit.Description = "Couch controls of the pad %i";
    Service = {
      ExecStart = "${couchPad} /dev/input/couch-pad-%i";
      # Quoted: systemd reads an unquoted value's words as further assignments
      Environment = [
        "\"COUCH_KEYBOARD=${couchOsk} ${oskStyle}\""
        "\"COUCH_HOME=${lib.getExe config.programs.firefox.finalPackage} --new-tab file://${startPage}\""
      ];
      Restart = "on-failure";
    };
  };

  # Udev starts couch-pad@ only as a pad connects, not for one already there
  # when the user manager starts
  systemd.user.services.couch-pads = {
    Unit.Description = "Couch controls of the pads connected before login";
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "couch-pads" ''
        shopt -s nullglob
        for pad in /dev/input/couch-pad-*; do
          ${pkgs.systemd}/bin/systemctl --user start --no-block "couch-pad@''${pad#/dev/input/couch-pad-}.service"
        done
      '');
    };
  };

  # On-screen output volume for the volume keys; the TV's own volume is out of
  # reach over HDMI, and Plexamp ignores MPRIS volume
  services.swayosd.enable = true;

  # The pad's B is Backspace: a page back, unless typing
  programs.firefox.profiles.personal.settings."browser.backspace_action" = 0;

  # The TV's physical DPI is low; size by the output scale instead
  programs.foot.settings.main = {
    dpi-aware = lib.mkForce "no";
    font = "monospace:size=14";
  };

  # The couch menu: one compact column, no search
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${FONT}:size=16";
        # The TV's physical DPI is low; size by the output scale instead
        dpi-aware = "no";
        # Over a full-screen app too
        layer = "overlay";
        hide-prompt = "yes";
        lines = 4;
        width = 18;
        line-height = 56;
        horizontal-pad = 13;
        vertical-pad = 13;
        inner-pad = 0;
      };
      colors = {
        background = "${colors.base00}ff";
        text = "${colors.base05}ff";
        selection = "${colors.base0A}ff";
        selection-text = "${colors.base00}ff";
        match = "${colors.base0A}ff";
        selection-match = "${colors.base00}ff";
        border = "${colors.base01}ff";
      };
      border = {
        width = 1;
        radius = 13;
        selection-radius = 13;
      };
    };
  };

  # Frecency-based dir jumping
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    setSessionVariables = true;
    download = "/mnt/wd-red/sftp/dnld";
    documents = "/mnt/wd-red/sftp/docs";
  };
}
