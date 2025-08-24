{ config, pkgs, ... }:
let
  inherit (config.home.sessionVariables) TERMINAL;
in
{
  home.packages = with pkgs; [
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler
    xfce.xfconf
    p7zip
    xarchiver
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
    };
  };

  # Thunar configuration
  xfconf.settings.thunar = {
    default-view = "ThunarDetailsView";
    last-menubar-visible = true;
    last-show-hidden = false;
    last-statusbar-visible = true;
    misc-expandable-folders = true;
  };

  # Custom actions configuration
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
      <icon>utilities-terminal</icon>
      <name>Open Terminal Here</name>
      <unique-id>1234567890123456-1</unique-id>
      <command>${TERMINAL} --working-directory=%f</command>
      <description>Open terminal in the current directory</description>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    </actions>
  '';

  # Hide Thunar Preferences and Bulk Rename from app launchers
  xdg.desktopEntries = {
    "thunar-settings" = {
      name = "Thunar Preferences";
      noDisplay = true;
    };
    "thunar-bulk-rename" = {
      name = "Bulk Rename";
      noDisplay = true;
    };
  };
}
