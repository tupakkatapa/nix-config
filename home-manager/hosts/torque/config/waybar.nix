{pkgs, ...}: let
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  blueberry = "${pkgs.blueberry}/bin/blueberry";

  # Colors
  background = "1e1e1e";
  foreground = "e5e5e5";
  accent = "ffce8a";
  inactive = "444444";
  blue = "7d9bba";
  cyan = "8be9fd";
  green = "66cc99";
  orange = "ebcb8b";
  red = "fb958b";
  yellow = "ebcb8b";
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
        "wlr/workspaces"
      ];

      modules-right = [
        "tray"
        "pulseaudio"
        "bluetooth"
        "network"
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
        format = " {percentage_free}% free";
        format-alt = " {free} free";
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

      "wlr/workspaces" = {
        format = "{icon}";
        on-click = "activate";
        format_icons = {
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
          "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo" = "";
          "alsa_output.pci-0000_0a_00.1.hdmi-stereo" = "";
          headphone = "";
          headset = "";
          default = ["" "" ""];
        };
        on-click = pavucontrol;
      };

      bluetooth = {
        format = " on";
        format-disabled = " off";
        format-connected = " {device_alias}";
        format-connected_battery = " {device_alias} {device_battery_percentage}%";
        on-click = blueberry;
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " wired";
        format-disconnected = "";
      };

      "clock#time" = {
        format = "{:%I:%M %p}";
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
        format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
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
        font-family: JetBrains Mono;
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
        color: #${cyan};
      }

      #bluetooth {
        color: #${cyan};
      }

      #bluetooth.disconnected {
        color: #${cyan};
      }

      #network {
        color: #${yellow};
      }

      #network.disconnected {
        color: #${yellow};
      }

      #battery {
        color: #${green};
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
