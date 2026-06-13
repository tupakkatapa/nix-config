{ config, pkgs, lib, customLib, ... }:
let
  inherit (config.home.sessionVariables) TERMINAL;

  # Override tumbler to exclude libgepub (EPUB support) which pulls in WebKitGTK
  # Saves 141.46 MiB from initrd by preventing 1.4 GiB WebKitGTK closure
  tumblerWithoutEpub = pkgs.tumbler.overrideAttrs (old: {
    buildInputs = lib.filter (x: (x.pname or "") != "libgepub") old.buildInputs;
  });

  extractHere = pkgs.writeShellApplication {
    name = "thunar-extract-here";
    runtimeInputs = [ pkgs.libarchive pkgs.libnotify ];
    text = ''
      f="$1"
      d="$(dirname "$f")"
      notify-send "Extracting" "$(basename "$f")"
      if bsdtar -xf "$f" -C "$d"; then
        notify-send "Extracted" "$(basename "$f")"
      else
        notify-send -u critical "Extract failed" "$(basename "$f")"
      fi
    '';
  };

  # Double-click handler: extract archive to /tmp + open dir in Thunar
  archiveOpen = pkgs.writeShellApplication {
    name = "thunar-archive-open";
    runtimeInputs = [ pkgs.libarchive pkgs.libnotify pkgs.thunar ];
    text = ''
      f="$1"
      base="$(basename "$f")"
      tmp="$(mktemp -d "/tmp/archive-XXXXXX-''${base%.*}")"
      notify-send "Extracting" "$base"
      if bsdtar -xf "$f" -C "$tmp"; then
        thunar "$tmp" &
      else
        notify-send -u critical "Extract failed" "$base"
        rmdir "$tmp" 2>/dev/null || true
      fi
    '';
  };

  archiveDesktop = pkgs.makeDesktopItem {
    name = "thunar-archive-open";
    desktopName = "Archive (Extract & Browse)";
    exec = "${archiveOpen}/bin/thunar-archive-open %f";
    icon = "package-x-generic";
    mimeTypes = customLib.xdg.mimes.archive;
    noDisplay = false;
  };
in
{
  home.packages = with pkgs; [
    thunar
    thunar-volman
    tumblerWithoutEpub
    xfconf
    libarchive
    p7zip
    unrar
    extractHere
    archiveOpen
    archiveDesktop
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
    last-show-hidden = true;
    last-statusbar-visible = true;
    misc-expandable-folders = true;
  };

  # Sidebar bookmarks
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    file:///home/${config.home.username}/Workspace Workspace
    file:///home/${config.home.username}/Downloads Downloads
    file:///mnt/sftp SFTP
  '';

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
    <action>
      <icon>archive-extract</icon>
      <name>Extract Here</name>
      <unique-id>1234567890123456-2</unique-id>
      <command>${extractHere}/bin/thunar-extract-here %f</command>
      <description>Extract archive into current directory</description>
      <patterns>*.zip;*.tar;*.tar.gz;*.tgz;*.tar.bz2;*.tbz2;*.tar.xz;*.txz;*.tar.zst;*.tzst;*.7z;*.rar;*.gz;*.bz2;*.xz;*.zst;*.lzma;*.lz;*.lzh;*.cab;*.iso;*.cbz;*.cbr</patterns>
      <other-files/>
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
