{ pkgs
, config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME TERMINAL;
  colors = (import ../../../colors.nix).${THEME};

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  blueberry = "${pkgs.blueberry}/bin/blueberry";
  bat = "${pkgs.bat}/bin/bat";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  jq = "${pkgs.jq}/bin/jq";
in
{
  home.packages = [ pkgs.font-awesome ];
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
    });
    settings.primary = {
      height = 20;
      margin-top = 3;
      margin-left = 10;
      margin-bottom = 0;
      margin-right = 10;
      layer = "top";
      spacing = 5;

      modules-left = [
        # "custom/menu"
        "custom/hostname"
        "cpu"
        "memory"
        "disk"
        "custom/player"
      ];

      modules-center = [
        # "custom/prev"
        "hyprland/workspaces"
        # "custom/next"
      ];

      modules-right = [
        "custom/ping-sweep"
        "tray"
        "pulseaudio"
        "bluetooth"
        "network"
        "battery"
        "clock#date"
        "clock#time"
        # "custom/help"
      ];

      cpu = {
        format = " {usage}%";
        max-length = 100;
        interval = 1;
      };

      memory = {
        format = " {}%";
        format-alt = " {used:0.1f}G";
        interval = 5;
        max-length = 10;
      };

      disk = {
        interval = 30;
        format = " {percentage_free}% free";
        format-alt = " {free} free";
      };

      "custom/player" = {
        exec-if = "${playerctl} status";
        exec = ''${playerctl} metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
        return-type = "json";
        interval = 2;
        max-length = 50;
        format = "{icon} {}";
        format-icons = {
          "Playing" = " ";
          "Paused" = " ";
          "Stopped" = " ";
        };
        on-click = "${playerctl} play-pause";
      };

      "hyprland/workspaces" = {
        format = "{icon}";
        on_click = "activate";
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

      "custom/hostname" = { exec = "echo $USER@$HOSTNAME"; };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = " 0%";
        format-icons = {
          "bluez_output.80_7B_1E_02_53_95.1" = ""; # CORSAIR VIRTUOSO XT Bluetooth
          "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo" = "";
          "alsa_output.pci-0000_0a_00.1.hdmi-stereo" = "";
          headphone = "";
          headset = "";
          default = [ "" "" "" ];
        };
        on-click = pavucontrol;
      };

      bluetooth = {
        format = " {status}";
        format-connected = " {num_connections} connected";
        tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        on-click = blueberry;
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " wired";
        format-disconnected = "";
      };

      "clock#time" = { format = "{:%H:%M}"; };

      "clock#date" = {
        format = "{:%d.%m.%Y}";
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
        format-icons = [ "" "" "" "" "" ];
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
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
        format = "  {}";
      };

      "custom/prev" = {
        format = "";
        on-click = ''
          current_ws=$(${hyprctl} monitors -j | ${jq} -r '.[0].activeWorkspace.id')
          ${hyprctl} dispatch workspace $(( current_ws - 1 ))
        '';
      };

      "custom/next" = {
        format = "";
        on-click = ''
          current_ws=$(${hyprctl} monitors -j | ${jq} -r '.[0].activeWorkspace.id')
          [ $(( current_ws + 1 )) -le 9 ] && ${hyprctl} dispatch workspace $(( current_ws + 1 ))
        '';
      };

      "custom/menu" = {
        format = "+";
        on-click = ''
          wofi
        '';
      };

      "custom/help" = {
        format = "?";
        on-click = ''
          ${TERMINAL} -e sh -c "sed -r 's:/nix/store/[a-z0-9]+-[a-zA-Z0-9.-]+/bin/::g' ~/hypr_binds.txt | tr -s ' ' | ${bat} --wrap never"
        '';
      };
    };
    style = ''
      /* Global Styles */
      * {
        font-family: ${FONT};
        font-size: 11px;
        font-weight: 900;
        margin: 0;
        padding: 0;
      }

      /* Waybar Styles */
      window#waybar {
        background-color: transparent;
        color: #${colors.base05};
        transition-property: background-color;
        transition-duration: 0.5s;
        border-radius: 0;
        margin: 0;
      }

      /* Workspace Styles */
      #workspaces {
        border-radius: 20px;
        padding: 0 10px;
        background-color: #${colors.base00};
      }

      /* Workspace Button Styles */
      #workspaces button {
        padding: 0 0;
        color: #${colors.base02};
        background-color: transparent;
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
      }

      #workspaces button.active {
        color: #${colors.base05};
      }

      /* Global Item Styles */
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
      #window,
      #bluetooth {
        padding: 0 15px;
        color: #${colors.base05};
        border-radius: 20px;
        background-color: #${colors.base00};
      }

      #custom-menu,
      #custom-prev,
      #custom-next,
      #custom-help {
        padding: 0 7px;
        color: #${colors.base02};
        border-radius: 20px;
        background-color: #${colors.base00};
      }

      /* Item Styles */
      #cpu {
        color: #${colors.base08};
      }

      #memory {
        color: #${colors.base0A};
      }

      #disk {
        color: #${colors.base0B};
      }

      #pulseaudio {
        color: #${colors.base0D};
      }

      #bluetooth {
        color: #${colors.base0C};
      }

      #bluetooth.disconnected {
        color: #${colors.base0C};
      }

      #network {
        color: #${colors.base09};
      }

      #network.disconnected {
        color: #${colors.base09};
      }

      #battery {
        color: #${colors.base0E};
      }

      #battery.charging,
      #battery.full,
      #battery.plugged {
        color: #${colors.base0B};
      }

      #battery.critical:not(.charging) {
        color: #${colors.base08};
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #${colors.base00};
      }
    '';
  };
}
