{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}: {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
    });
    settings.primary = {
      mode = "dock";
      layer = "top";
      position = "top";
      height = 20;
      margin-top = 3;
      margin-left = 10;
      margin-bottom = 0;
      margin-right = 10;
      spacing = 5;

      modules-left = ["cpu" "memory" "disk" "mpris"];
      modules-center = ["wlr/workspaces"];
      modules-right = [
        "battery"
        "pulseaudio"
        "bluetooth"
        "network"
        "tray"
        "clock"
      ];

      cpu = {
        interval = 1;
        format = " {usage}%";
        max-length = 100;
        on-click = "";
      };

      disk = {
        interval = 30;
        format = " {percentage_free}% free";
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
        ignored-players = ["firefox"];
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
        };
      };

      battery = {
        bat = "BAT0";
        adapter = "ADP0";
        interval = 60;
        states = {
          warning = 30;
          critical = 15;
        };
        on-click = "sh ~/.config/waybar/scripts/power-profiles";
        max-length = 20;
        format = "{icon} {capacity}%";
        format-warning = "{icon} {capacity}%";
        format-critical = "{icon} {capacity}%";
        format-charging = "<span font-family='Font Awesome 6 Free'></span> {capacity}%";
        format-plugged = "  {capacity}%";
        format-alt = "{icon} {time}";
        format-full = "  {capacity}%";
        format-icons = [" " " " " " " " " "];
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-bluetooth = "  {volume}%";
        format-bluetooth-muted = "婢 ";
        format-muted = "婢";
        format-icons = {
          "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo" = "";
          "alsa_output.pci-0000_0a_00.1.hdmi-stereo" = "";
          headphone = "";
          "hands-free" = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = ["" "" ""];
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
    style = ''
* {
  /* `otf-font-awesome` is required to be installed for icons */
  font-family: JetBrains Mono;
  font-size: 11px;
  font-weight: 900;
  margin: 0;
  padding: 0;
}

window#waybar {
  /* background-color: rgba(26, 27, 38, 0.5); */
  background-color: transparent;
  color: #ffffff;
  transition-property: background-color;
  transition-duration: 0.5s;
  /* border-top: 8px transparent; */
  border-radius: 0px;
  transition-duration: 0.5s;
  margin: 0px 0px;
}

window#waybar.hidden {
  opacity: 0.2;
}

#workspaces button {
  padding: 0 0px;
  color: #7984a4;
  background-color: transparent;
  /* Use box-shadow instead of border so the text isn't offset */
  box-shadow: inset 0 -3px transparent;
  /* Avoid rounded borders under each workspace name */
  border: none;
  border-radius: 0;
}

#workspaces button.focused {
  background-color: transparent;
}
#workspace button.hover {
  background-color: transparent;
}
#workspaces button.active {
  color: #fff;
}

#workspaces button.urgent {
  background-color: transparent;
}

#window {
  /* border-radius: 20px; */
  /* padding-left: 10px; */
  /* padding-right: 10px; */
  color: #64727d;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#mpd,
#custom-roll,
#custom-next,
#mpris,
#bluetooth,
#custom-hyprPicker,
#custom-power-menu,
#custom-spotify,
#custom-weather,
#custom-weather.severe,
#custom-weather.sunnyDay,
#custom-weather.clearNight,
#custom-weather.cloudyFoggyDay,
#custom-weather.cloudyFoggyNight,
#custom-weather.rainyDay,
#custom-weather.rainyNight,
#custom-weather.showyIcyDay,
#custom-weather.snowyIcyNight,
#custom-weather.default {
  padding: 0px 15px;
  color: #e5e5e5;
  /* color: #bf616a; */
  border-radius: 20px;
  background-color: #1e1e1e;
}

#window,
#workspaces {
  border-radius: 20px;
  padding: 0px 10px;
  background-color: #1e1e1e;
}

#cpu {
  color: #fb958b;
  background-color: #1e1e1e;
}

#memory {
  color: #ebcb8b;
  background-color: #1e1e1e;
}

#custom-roll {
  color: #ff79c6	;
  background-color: #1e1e1e;
}

#custom-next {
  color: #ff79c6;
  background-color: #1e1e1e;
}

#custom-power-menu {
  border-radius: 9.5px;
  background-color: #1b242b;
  border-radius: 7.5px;
  padding: 0 0px;
}

#custom-launcher {
  background-color: #1b242b;
  color: #6a92d7;
  border-radius: 7.5px;
  padding: 0 0px;
}

#custom-weather.severe {
  color: #eb937d;
}

#custom-weather.sunnyDay {
  color: #c2ca76;
}

#custom-weather.clearNight {
  color: #cad3f5;
}

#custom-weather.cloudyFoggyDay,
#custom-weather.cloudyFoggyNight {
  color: #c2ddda;
}

#custom-weather.rainyDay,
#custom-weather.rainyNight {
  color: #5aaca5;
}

#custom-weather.showyIcyDay,
#custom-weather.snowyIcyNight {
  color: #d6e7e5;
}

#custom-weather.default {
  color: #dbd9d8;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
  margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
  margin-right: 0;
}

#pulseaudio {
  color: #7d9bba;
}

#backlight {
  /* color: #EBCB8B; */
  color: #8fbcbb;
}

#clock {
  color: #c8d2e0;
  /* background-color: #14141e; */
}

#battery {
  color: #c0caf5;
  /* background-color: #90b1b1; */
}

#battery.charging,
#battery.full,
#battery.plugged {
  color: #26a65b;
  /* background-color: #26a65b; */
}

@keyframes blink {
  to {
    background-color: rgba(30, 34, 42, 0.5);
    color: #abb2bf;
  }
}

#battery.critical:not(.charging) {
  color: #f53c3c;
  animation-name: blink;
  animation-duration: 0.5s;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}

label:focus {
  background-color: #000000;
}

#disk {
  color: #66cc99;
  background-color: #1e1e1e;
}

#mpris {
  background-color: #1e1e1e;
  color: #abb2bf;
  min-width: 100px;
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

#custom-media {
  background-color: #66cc99;
  color: #2a5c45;
  min-width: 100px;
}

#custom-media.custom-spotify {
  background-color: #66cc99;
}

#custom-media.custom-vlc {
  background-color: #ffa000;
}

#temperature {
  background-color: #f0932b;
}

#temperature.critical {
  background-color: #eb4d4b;
}

#tray > .passive {
  -gtk-icon-effect: dim;
}

#tray > .needs-attention {
  -gtk-icon-effect: highlight;
  background-color: #eb4d4b;
}

#idle_inhibitor {
  background-color: #2d3436;
}

#idle_inhibitor.activated {
  background-color: #ecf0f1;
  color: #2d3436;
}

#language {
  background: #00b093;
  color: #740864;
  padding: 0 0px;
  margin: 0 5px;
  min-width: 16px;
}

#keyboard-state {
  background: #97e1ad;
  color: #000000;
  padding: 0 0px;
  margin: 0 5px;
  min-width: 16px;
}

#keyboard-state > label {
  padding: 0 0px;
}

#keyboard-state > label.locked {
  background: rgba(0, 0, 0, 0.2);
}
    '';
  };
}