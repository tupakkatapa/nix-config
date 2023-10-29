{
  pkgs,
  config,
  ...
}: let
  inherit (config.home.sessionVariables) FONT TERMINAL EDITOR;
  inherit (import ./colors.nix) background foreground accent inactive blue cyan green orange pink purple red yellow;

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  blueberry = "${pkgs.blueberry}/bin/blueberry";
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
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
        "custom/hostname"
        "cpu"
        "memory"
        "disk"
        "custom/player"
      ];

      modules-center = [
        "hyprland/workspaces"
      ];

      modules-right = [
        "tray"
        "pulseaudio"
        "bluetooth"
        "network"
        "battery"
        "clock#date"
        "clock#time"
      ];

      cpu = {
        format = " {usage}%";
        max-length = 100;
        interval = 1;
      };

      memory = {
        format = "  {}%";
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

      "custom/hostname" = {
        exec = "echo $USER@$HOSTNAME";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = " 0%";
        format-icons = {
          "bluez_output.80_7B_1E_02_53_95.1" = ""; # CORSAIR VIRTUOSO XT Bluetooth
          "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo" = "";
          "alsa_output.pci-0000_0a_00.1.hdmi-stereo" = "";
          headphone = "";
          headset = "";
          default = ["" "" ""];
        };
        on-click = pavucontrol;
      };

      bluetooth = {
        format = " on";
        format-disabled = " off";
        format-connected = " {device_alias}";
        format-connected-battery = " {device_alias} {device_battery_percentage}%";
        on-click = blueberry;
        tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\t\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t\t{device_address}";
        tooltip-format-enumerate-connected-battery = "{device_alias}\t\t{device_address}\t{device_battery_percentage}%";
        # Display order preference, since only one device is shown
        format-device-preference = ["CORSAIR VIRTUOSO XT Bluetooth" "MX Keys" "MX Master 2S"];
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " wired";
        format-disconnected = "";
      };

      "clock#time" = {
        format = "{:%H:%M}";
      };

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
            months = "<span color='#${red}'><b>{}</b></span>";
            days = "<span color='#${foreground}'><b>{}</b></span>";
            weeks = "<span color='#${inactive}'><b>W{}</b></span>";
            weekdays = "<span color='#${yellow}'><b>{}</b></span>";
            today = "<span color='#${green}'><b><u>{}</u></b></span>";
          };
        };
      };

      battery = {
        bat = "BAT0";
        interval = 10;
        format-icons = ["" "" "" "" ""];
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        onclick = "";
      };

      tray = {
        spacing = 10;
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
        color: #${foreground};
        transition-property: background-color;
        transition-duration: 0.5s;
        border-radius: 0;
        margin: 0;
      }

      /* Workspace Styles */
      #workspaces {
        border-radius: 20px;
        padding: 0 10px;
        background-color: #${background};
      }

      /* Workspace Button Styles */
      #workspaces button {
        padding: 0 0;
        color: #${inactive};
        background-color: transparent;
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
      }

      #workspaces button.active {
        color: #${foreground};
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
      #bluetooth {
        padding: 0 15px;
        color: #${foreground};
        border-radius: 20px;
        background-color: #${background};
      }

      /* Item Styles */
      #cpu {
        color: #${red};
      }

      #memory {
        color: #${yellow};
      }

      #disk {
        color: #${green};
      }

      #pulseaudio {
        color: #${blue};
      }

      #bluetooth {
        color: #${cyan};
      }

      #bluetooth.disconnected {
        color: #${cyan};
      }

      #network {
        color: #${orange};
      }

      #network.disconnected {
        color: #${orange};
      }

      #battery {
        color: #${purple};
      }

      #battery.charging,
      #battery.full,
      #battery.plugged {
        color: #${green};
      }

      #battery.critical:not(.charging) {
        color: #${red};
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
        background-color: #${background};
      }
    '';
  };
}
