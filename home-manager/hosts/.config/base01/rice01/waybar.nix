{ pkgs
, config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = customLib.colors.${THEME};
  rice = import ./config.nix { inherit customLib config; };

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  blueberry = "${pkgs.blueberry}/bin/blueberry";
in
{
  programs.waybar = {
    settings.primary = {
      height = 20;
      margin-top = rice.spacing;
      margin-left = rice.spacing;
      margin-right = rice.spacing;
      layer = "top";
      spacing = rice.spacing / 2;

      modules-left = [
        "custom/hostname"
        "custom/red-dot"
        "custom/yellow-dot"
        "custom/green-dot"
        "custom/player"
      ];

      modules-center = [
        "hyprland/workspaces"
      ];

      modules-right = [
        "custom/ping-sweep"
        "tray"
        "pulseaudio"
        "bluetooth"
        "network"
        "battery"
        "clock#datetime"
      ];

      "custom/player" = {
        exec-if = "${playerctl} status";
        exec = ''${playerctl} metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
        return-type = "json";
        interval = 2;
        max-length = 100;
        format = "{icon} {}";
        format-icons = {
          "Playing" = "";
          "Paused" = "";
          "Stopped" = "";
        };
        on-click = "${playerctl} play-pause";
      };

      "hyprland/workspaces" = {
        format = "{icon}";
        on_click = "activate";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
        };
      };

      "custom/hostname" = {
        exec = "echo $USER@$HOSTNAME";
        tooltip = false;
      };

      "custom/red-dot" = {
        format = "";
        tooltip = false;
      };

      "custom/yellow-dot" = {
        format = "";
        tooltip = false;
      };

      "custom/green-dot" = {
        format = "";
        tooltip = false;
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "  0%";
        format-icons = {
          "bluez_output.80_7B_1E_02_53_95.1" = ""; # CORSAIR VIRTUOSO XT Bluetooth
          "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo" = "";
          "alsa_output.pci-0000_0a_00.1.hdmi-stereo" = "󰍹";
          headphone = "";
          headset = "";
          default = [ "" "" "" ];
        };
        on-click = pavucontrol;
      };

      bluetooth = {
        format = "󰂯 {status}";
        format-connected = "󰂯 {num_connections} connected";
        tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        on-click = blueberry;
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " wired";
        format-disconnected = "";
        tooltip = false;
      };

      "clock#datetime" = {
        format = "{:%d.%m.%Y | %H:%M}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          "mode-mon-col" = 3;
          "weeks-pos" = "right";
          "on-scroll" = 1;
          "on-click-right" = "mode";
          format = {
            months = "<span color='#${colors.base08}'><b>{}</b></span>";
            days = "<span color='#${colors.base05}'><b>{}</b></span>";
            weeks = "<span color='#${colors.base02}'><b>W{}</b></span>";
            weekdays = "<span color='#${colors.base0A}'><b>{}</b></span>";
            today = "<span color='#${colors.base0B}'><b><u>{}</u></b></span>";
          };
        };
      };

      battery = {
        bat = "BAT0";
        interval = 10;
        format-icons = [ "󰂎" "󱊡" "󱊢" "󱊣" ];
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        onclick = "";
      };

      tray = { spacing = 10; };

      "custom/ping-sweep" = {
        exec = ''
          interface_name="enp3s0"
          local_ip=$(${pkgs.iproute2}/bin/ip -4 addr show $interface_name | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
          ips=$(${pkgs.ping-sweep}/bin/ping-sweep -s 10.42.0.0/24)

          # Filters
          ips=$(echo "$ips" | grep -v "$local_ip")

          # Format
          ip_suffixes=$(echo "$ips" | sed 's/10\.42\.0\././' | sort -n)
          echo '{"text": "'$ip_suffixes'"}'
        '';
        interval = 30;
        return-type = "json";
        format = " {}";
      };




    };
    style = ''
      * {
        border-radius: ${toString rice.rounding}px;
        font-family: ${FONT};
        font-size: 11px;
        font-weight: 900;
      }

      window#waybar {
        background-color: transparent;
        color: #${colors.base05};
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      #workspaces {
        padding: 0 10px;
        background-color: #${colors.base00};
        border: ${toString rice.border.size}px solid #${rice.border.inactive};
      }

      #workspaces button {
        color: #${colors.base02};
        background-color: transparent;
        box-shadow: inset 0 -3px transparent;
        border: none;
        min-width: 20px;
      }

      #workspaces button.active {
        color: #${colors.base05};
      }

      /* Main module styles */
      #clock,
      #battery,
      #network,
      #pulseaudio,
      #tray,
      #custom-player,
      #custom-hostname,
      #custom-ping-sweep,
      #window,
      #bluetooth {
        padding: 0 15px;
        color: #${colors.base05};
        background-color: #${colors.base00};
        border: ${toString rice.border.size}px solid #${rice.border.inactive};
      }

      /* All dot modules */
      #custom-red-dot,
      #custom-yellow-dot,
      #custom-green-dot {
        padding: 0 5px;
        background-color: transparent;
      }

      /* Dot-specific colors */
      #custom-red-dot { color: #${colors.base08}; }
      #custom-yellow-dot { color: #${colors.base0A}; }
      #custom-green-dot {
        color: #${colors.base0B};
        padding: 0 8px 0 5px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #${colors.base00};
      }

      #custom-hostname {
        margin-left: ${toString (rice.spacing / 2)}px;
      }

      #clock.datetime {
        margin-right: ${toString (rice.spacing / 2)}px;
      }
    '';
  };
}
