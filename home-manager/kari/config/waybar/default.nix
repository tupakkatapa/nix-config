{pkgs, ...}: let
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
    });
    settings.primary = {
      mode = "dock";
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
        "pulseaudio"
        "bluetooth"
        "network"
        "tray"
        "clock"
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
        on-click = "blueberry";
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " wired";
        format-disconnected = "";
      };

      clock = {
        format = "<span color='#bf616a'> </span>{:%I:%M %p}";
        format-alt = "<span color='#bf616a'> </span>{:%d.%m.%Y}";
        tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
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
        color: #ffffff;
        transition-property: background-color;
        transition-duration: 0.5s;
        border-radius: 0;
        margin: 0;
      }

      /* Workspace Styles */
      #workspaces {
        border-radius: 20px;
        padding: 0 10px;
        background-color: #1e1e1e;
      }

      /* Workspace Button Styles */
      #workspaces button {
        padding: 0 0;
        color: #7984a4;
        background-color: transparent;
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
      }

      #workspaces button.active {
        color: #fff;
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
        color: #e5e5e5;
        border-radius: 20px;
        background-color: #1e1e1e;
      }

      /* Item Styles */
      #cpu {
        color: #fb958b;
        background-color: #1e1e1e;
      }

      #memory {
        color: #ebcb8b;
        background-color: #1e1e1e;
      }

      #pulseaudio {
        color: #7d9bba;
      }

      #disk {
        color: #66cc99;
        background-color: #1e1e1e;
      }

      #bluetooth {
        color: #8be9fd;
      }

      #bluetooth.disconnected {
        color: #f53c3c;
      }

      #network {
        color: #ebcb8b;
      }

      #network.disconnected {
        color: #f53c3c;
      }

      #battery {
        color: #c0caf5;
      }

      #battery.charging,
      #battery.full,
      #battery.plugged {
        color: #26a65b;
      }

      #battery.critical:not(.charging) {
        color: #f53c3c;
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
        background-color: #eb4d4b;
      }
    '';
  };
}
