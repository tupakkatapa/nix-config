{ pkgs
, config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = customLib.colors.${THEME};

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  blueberry = "${pkgs.blueberry}/bin/blueberry";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  jq = "${pkgs.jq}/bin/jq";
  curl = "${pkgs.curl}/bin/curl";
in
{
  programs.waybar = {
    settings.primary = {
      height = 24;
      margin-top = 0;
      margin-left = 0;
      margin-bottom = 0;
      margin-right = 0;
      layer = "top";
      spacing = 1;

      modules-left = [
        "custom/menu"
        "custom/hostname"
        "cpu"
        "memory"
        "disk"
        "custom/player"
      ];

      modules-center = [
        "custom/prev"
        "hyprland/workspaces"
        "custom/next"
      ];

      modules-right = [
        "custom/ping-sweep"
        "tray"
        "pulseaudio"
        "bluetooth"
        "network"
        "battery"
        "custom/crypto"
        "custom/weather"
        "clock#date"
        "clock#time"
        "custom/help"
      ];

      cpu = {
        format = "[ CPU {usage}% ]";
        max-length = 100;
        interval = 1;
      };

      memory = {
        format = "[ MEM {}% ]";
        format-alt = "[ MEM {used:0.1f}G ]";
        interval = 5;
      };

      disk = {
        interval = 30;
        format = "[ DISK {percentage_free}% ]";
        format-alt = "[ DISK {free} ]";
      };

      "custom/player" = {
        exec-if = "${playerctl} status";
        exec = ''
          info=$(${playerctl} metadata --format '{{artist}} - {{title}}')
          if [ ''${#info} -gt 46 ]; then
            info="$(echo "$info" | cut -c 1-46)..."
          fi
          echo "{\"text\": \"$info\", \"alt\": \"$(${playerctl} status)\", \"tooltip\": \"$(${playerctl} metadata --format '{{title}} ({{artist}} - {{album}})')\"}"
        '';
        return-type = "json";
        interval = 2;
        format = "[ {} ]";
      };

      "hyprland/workspaces" = {
        format = "{icon}";
        on_click = "activate";
        format-icons = {
          "1" = "[ 1 ]";
          "2" = "[ 2 ]";
          "3" = "[ 3 ]";
          "4" = "[ 4 ]";
          "5" = "[ 5 ]";
          "6" = "[ 6 ]";
          "7" = "[ 7 ]";
          "8" = "[ 8 ]";
          "9" = "[ 9 ]";
        };
      };

      "custom/hostname" = {
        exec = "echo $USER@$HOSTNAME";
        format = "[ {} ]";
        tooltip = false;
      };

      pulseaudio = {
        format = "[ VOL {volume}% ]";
        format-muted = "[ VOL MUTED ]";
        on-click = pavucontrol;
      };

      bluetooth = {
        format = "[ BT ]";
        format-connected = "[ BT {num_connections} ]";
        tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        on-click = blueberry;
      };

      network = {
        format-wifi = "[ WIFI {signalStrength}% ]";
        format-ethernet = "[ ETH ]";
        format-disconnected = "[ OFFLINE ]";
        tooltip = false;
      };

      "clock#time" = {
        format = "[ {:%H:%M} ]";
        tooltip = false;
      };

      "clock#date" = {
        format = "[ {:%d.%m.%Y} ]";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          "mode-mon-col" = 3;
          "weeks-pos" = "right";
          "on-scroll" = 1;
          "on-click-right" = "mode";
          format = {
            months = "<span><b>{}</b></span>";
            days = "<span><b>{}</b></span>";
            weeks = "<span><b>W{}</b></span>";
            weekdays = "<span><b>{}</b></span>";
            today = "<span><b><u>{}</u></b></span>";
          };
        };
      };

      battery = {
        bat = "BAT0";
        interval = 10;
        format = "[ BAT {capacity}% ]";
        format-charging = "[ CHG {capacity}% ]";
        onclick = "";
      };

      tray = { spacing = 10; };

      "custom/ping-sweep" = {
        exec = ''
          interface_name="enp3s0"
          local_ip=$(${pkgs.iproute2}/bin/ip -4 addr show $interface_name | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
          ips=$(${pkgs.ping-sweep}/bin/ping-sweep -s 192.168.1.0/24)

          # Filters
          ips=$(echo "$ips" | grep -v "$local_ip")
          # ips=$(echo "$ips" | grep -v "192.168.1.1")

          # Format
          ip_suffixes=$(echo "$ips" | sed 's/192\.168\.1\././' | sort -n)
          echo '{"text": "'$ip_suffixes'"}'
        '';
        interval = 30;
        return-type = "json";
        format = "[ IPS {} ]";
      };

      "custom/crypto" = {
        exec = ''
          data=$(${curl} -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_24hr_change=true")
          btc_price=$(echo $data | ${jq} -r '.bitcoin.usd')
          btc_change=$(echo $data | ${jq} -r '.bitcoin.usd_24h_change')
          eth_price=$(echo $data | ${jq} -r '.ethereum.usd')
          eth_change=$(echo $data | ${jq} -r '.ethereum.usd_24h_change')
          text=$(printf "%+.2f%%" "$btc_change")
          tooltip=$(printf "BTC: \$%s, 24h:%+.2f%% | ETH: \$%s, 24h:%+.2f%%" "$btc_price" "$btc_change" "$eth_price" "$eth_change")
          echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\"}"
        '';
        return-type = "json";
        interval = 3600;
        format = "[ BTC {} ]";
      };

      "custom/weather" = {
        exec = ''
          weather=$(${curl} -s "wttr.in/?format=%t,+%w")
          weather=''${weather/#Unknown location*/Unknown Location}
          echo "{\"text\": \"$weather\"}"
        '';
        return-type = "json";
        interval = 3600;
        format = "[ WX {} ]";
      };

      "custom/prev" = {
        format = "&lt;&lt;"; # Using HTML entity for < character
        on-click = ''
          current_ws=$(${hyprctl} monitors -j | ${jq} -r '.[0].activeWorkspace.id')
          ${hyprctl} dispatch workspace $(( current_ws - 1 ))
        '';
        tooltip = false;
      };

      "custom/next" = {
        format = ">>";
        on-click = ''
          current_ws=$(${hyprctl} monitors -j | ${jq} -r '.[0].activeWorkspace.id')
          [ $(( current_ws + 1 )) -le 9 ] && ${hyprctl} dispatch workspace $(( current_ws + 1 ))
        '';
        tooltip = false;
      };

      "custom/menu" = {
        format = "[ MENU ]";
        on-click = ''
          wofi
        '';
        tooltip = false;
      };

      "custom/help" = {
        format = "[ HELP ]";
        on-click = ''
          sed -r 's:/nix/store/[a-z0-9]+-[a-zA-Z0-9.-]+/bin/::g' ~/hypr_binds.txt |
          tr -s ' ' |
          wofi --show dmenu
        '';
        tooltip = false;
      };
    };
    style = ''
      * {
        border-radius: 0px;
        font-family: ${FONT}, monospace;
        font-size: 12px;
        font-weight: 700;
        transition: none;
      }

      window#waybar {
        background-color: #${colors.base00};
        color: #${colors.base05};
        border-bottom: 2px solid #${colors.base02};
      }

      #workspaces {
        background-color: #${colors.base00};
        margin: 0;
        padding: 0;
      }

      #workspaces button {
        color: #${colors.base04};
        background-color: transparent;
        box-shadow: none;
        border-radius: 0;
        margin: 0;
        padding: 0 6px;
        border-bottom: 2px solid #${colors.base02};
      }

      #workspaces button.active {
        color: #${colors.base00};
        background-color: #${colors.base0D};
        font-weight: bold;
        border-bottom: 2px solid #${colors.base02};
      }

      #workspaces button.urgent {
        background-color: #${colors.base08};
        color: #${colors.base00};
      }

      #custom-menu {
        color: #${colors.base00};
        background-color: #${colors.base0D};
        font-weight: bold;
        border-bottom: 2px solid #${colors.base02};
      }

      #custom-help {
        color: #${colors.base00};
        background-color: #${colors.base09};
        font-weight: bold;
        border-bottom: 2px solid #${colors.base02};
      }

      #custom-prev, #custom-next {
        color: #${colors.base0D};
        font-weight: bold;
        border-bottom: 2px solid #${colors.base02};
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #network,
      #pulseaudio,
      #tray,
      #custom-player,
      #custom-hostname,
      #custom-ping-sweep,
      #custom-weather,
      #custom-crypto,
      #window,
      #bluetooth,
      #custom-prev,
      #custom-next,
      #custom-menu,
      #custom-help {
        padding: 0 5px;
        margin: 0;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #${colors.base0A};
      }

      @keyframes blink {
        from {
          background-color: #${colors.base08};
          color: #${colors.base00};
        }
        to {
          background-color: #${colors.base00};
          color: #${colors.base08};
        }
      }

      #battery.critical:not(.charging) {
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }
    '';
  };
}
