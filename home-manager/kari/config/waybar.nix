{ outputs, config, lib, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    settings = {
      primary = {
        mode = "dock";
        layer = "top";
        height = 20;
        position = "top";
        margin-top = 3;
        margin-left = 10;
        margin-right = 10;
        margin-bottom = 0;
        spacing = 5;

        cpu = {
          interval = 1;
          format = " {usage}%";
          max-length = 100;
          on-click = "";
        };

        memory = {
          interval = 30;
          format = " {}%";
          format-alt = " {used:0.1f}G";
          max-length = 10;
        };

        mpris = {
          format = "{status_icon} {artist} - {title}";
          format-paused = "{status_icon} {artist} - {title}";
          interval = 10;
          ignored-players = [ "firefox" ];
          status-icons = {
            paused = "";
            playing = "";
          };
          on-click = "playerctl -p Plexamp play-pause";
        };

        "wlr/workspaces" = {
          format = "{icon}";
          on-click = "activate";
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
            "urgent" = "";
            "active" = "";
            "default" = "";
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "  {volume}%";
          format-bluetooth-muted = "婢 ";
          format-muted = "婢";
          format-icons = {
            "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo" = "";
            "alsa_output.pci-0000_0a_00.1.hdmi-stereo" = "";
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        bluetooth = {
          format = " on";
          format-disabled = " off";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          on-click = "blueberry";
        };

        network = {
          format-wifi = "直 {signalStrength}%";
          format-ethernet = " wired";
          format-disconnected = "睊";
        };

        clock = {
          format = "<span color='#bf616a'> </span>{:%I:%M %p}";
          format-alt = "<span color='#bf616a'> </span>{:%d.%m.%Y}";
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };

        tray = {
          icon-size = 21;
          spacing = 10;
        };








      };


    };
  };
}
