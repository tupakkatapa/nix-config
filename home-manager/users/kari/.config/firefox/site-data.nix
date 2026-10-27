# Extension and site state that a fresh profile would otherwise lose
{ pkgs
, lib
, config
, osConfig
, ...
}:
let
  inherit (pkgs) firefox-addons;

  # Extension settings, seeded into a fresh profile. Each extension reads
  # either storage.local or storage.sync, check with `browser.storage.<area>.get()`
  # in its about:debugging console.
  localSettings = {
    # Skips the install-time help tab
    ${firefox-addons.sponsorblock.addonId} = { alreadyInstalled = true; };
  };
  syncSettings = {
    ${firefox-addons.darkreader.addonId} = { detectDarkTheme = true; };
    ${firefox-addons.vimium.addonId} = lib.importJSON ./extension-settings/vimium.json;
    ${firefox-addons.sponsorblock.addonId} = lib.importJSON ./extension-settings/sponsorblock.json;
  };

  # Firefox's storage.sync database (schema version 2), which has no
  # declarative equivalent to storage.local's browser-extension-data
  syncSeed = pkgs.writeText "storage-sync-v2.sql" ''
    PRAGMA user_version = 2;
    CREATE TABLE storage_sync_data (ext_id TEXT NOT NULL PRIMARY KEY, data TEXT, sync_change_counter INTEGER NOT NULL DEFAULT 1);
    CREATE TABLE storage_sync_mirror (guid TEXT NOT NULL PRIMARY KEY, ext_id TEXT UNIQUE, data TEXT,
      CHECK((ext_id IS NULL AND data IS NULL) OR (ext_id IS NOT NULL AND data IS NOT NULL)));
    CREATE TABLE meta (key TEXT PRIMARY KEY, value NOT NULL) WITHOUT ROWID;
    ${lib.concatStrings (lib.mapAttrsToList (id: data: ''
      INSERT INTO storage_sync_data (ext_id, data) VALUES ('${id}', '${lib.replaceStrings [ "'" ] [ "''" ] (builtins.toJSON data)}');
    '') syncSettings)}
  '';

  # Torrent Control stores its server password in storage.local, so its
  # storage.js is written at activation instead of linked from the store
  torrentControl = {
    id = firefox-addons.torrent-control.addonId;
    creds = osConfig.age.secrets.torrent-control-creds.path or null;
    filter = if torrentControl.creds == null then "." else
    ''.servers[0].username = $c[0]["rpc-username"] | .servers[0].password = $c[0]["rpc-password"]'';
  };

  # Bitwarden prefills the login email it remembers, kept out of the repo
  bitwarden = {
    id = firefox-addons.bitwarden.addonId;
    email = osConfig.age.secrets.bitwarden-email.path or null;
  };

  # Host permissions of MV3 extensions, which policy installs never grant
  hostPermissions = {
    ${firefox-addons.vimium.addonId} = [ "<all_urls>" ];
    ${firefox-addons.youtube-shorts-block.addonId} = [ "*://*.youtube.com/*" "*://m.youtube.com/*" ];
  };
  extensionPreferences = pkgs.writeText "extension-preferences.json" (builtins.toJSON
    (lib.mapAttrs (_: origins: { permissions = [ ]; inherit origins; }) hostPermissions));

  # Site settings kept in cookies or localStorage. uBlock Origin writes them
  # on every page load, so a change made in-page lasts until the next load.
  ublockFilters = [
    # YouTube: ambient mode and subtitles off
    "www.youtube.com##+js(trusted-set-cookie, PREF, f6=40000000&f5=30000&f7=100&tz=Europe.Helsinki, 1year, /, domain, youtube.com)"
    ''www.youtube.com##+js(trusted-set-local-storage-item, yt-player-caption-persistence, {"data":"true"\,"expiration":4915180762515\,"creation":1793116762515})''

    # Slack: dark theme
    "app.slack.com##+js(trusted-set-local-storage-item, slack-client-theme, dark)"
  ];
in
{
  programs.firefox = {
    # Managed storage, which overrides the extensions' own settings
    policies."3rdparty".Extensions = {
      ${firefox-addons.ublock-origin.addonId} = {
        # Trusted, so their scriptlets may write cookies and localStorage
        adminSettings = builtins.toJSON (lib.recursiveUpdate
          (lib.importJSON ./extension-settings/ublock.json)
          { userSettings.userFiltersTrusted = true; });
        toOverwrite.filters = ublockFilters;
      };
      ${firefox-addons.privacy-badger.addonId}.showIntroPage = false;
      ${firefox-addons.bitwarden.addonId}.environment.base = "https://vault.coditon.com";
    };

    profiles.personal.extensions.settings =
      lib.mapAttrs (_: settings: { inherit settings; }) localSettings;
  };

  # Seeds a fresh profile; each file is built aside and moved in only when
  # complete, and a failure warns instead of failing the whole activation
  home.activation.firefoxSeed = lib.hm.dag.entryAfter [ "linkGeneration" ] (''
    firefoxSeed() {
      local target="$1" mode="$2" tmp
      shift 2
      [ -e "$target" ] && return 0
      tmp=$(mktemp)
      if "$@" "$tmp"; then
        run install -D -m "$mode" "$tmp" "$target"
      else
        warnEcho "Firefox: could not seed $target"
      fi
      rm -f "$tmp"
    }
    seedSyncStorage() { ${pkgs.sqlite}/bin/sqlite3 "$1" < ${syncSeed}; }
    seedPreferences() { cp ${extensionPreferences} "$1"; }
    seedBitwarden() {
      ${pkgs.jq}/bin/jq -n --rawfile e ${toString bitwarden.email} \
        '{global_loginEmail_storedEmail: {__json__: true, value: ($e | rtrimstr("\n") | tojson)}}' > "$1"
    }
    seedTorrentControl() {
      ${pkgs.jq}/bin/jq ${lib.optionalString (torrentControl.creds != null) "--slurpfile c ${torrentControl.creds}"} \
        ${lib.escapeShellArg torrentControl.filter} ${./extension-settings/torrent-control.json} > "$1"
    }
  '' + lib.concatMapStrings
    (profile:
      let dir = "$HOME/${config.programs.firefox.configPath}/${profile}"; in ''
        firefoxSeed "${dir}/storage-sync-v2.sqlite" 644 seedSyncStorage
        firefoxSeed "${dir}/extension-preferences.json" 644 seedPreferences
        firefoxSeed "${dir}/browser-extension-data/${torrentControl.id}/storage.js" 600 seedTorrentControl
      '' + lib.optionalString (bitwarden.email != null) ''
        firefoxSeed "${dir}/browser-extension-data/${bitwarden.id}/storage.js" 600 seedBitwarden
      '')
    (lib.attrNames config.programs.firefox.profiles));
}
