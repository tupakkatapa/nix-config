{ pkgs
, lib
, config
, customLib
, osConfig
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = customLib.colors.${THEME};

  # Convert about:config prefs to policy format
  lockPrefs = builtins.mapAttrs (_: value: { Value = value; Status = "locked"; });

  inherit (pkgs) firefox-addons;

  # Extension settings, seeded into a fresh profile. Each extension reads
  # either storage.local or storage.sync, check with `browser.storage.<area>.get()`
  # in its about:debugging console.
  localSettings = {
    # Skips the install-time help tab
    ${firefox-addons.sponsorblock.addonId} = { alreadyInstalled = true; };
    ${firefox-addons.dark-background-light-text.addonId} = {
      default_foreground_color = "#${colors.base05}";
      default_background_color = "#${colors.base00}";
      default_link_color = "#${colors.base0D}";
      default_visited_color = "#${colors.base0E}";
      default_active_color = "#${colors.base08}";
      default_selection_color = "#${colors.base02}";
    };
  };
  syncSettings = {
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

  # Host permissions of MV3 extensions, which policy installs never grant
  hostPermissions = {
    ${firefox-addons.vimium.addonId} = [ "<all_urls>" ];
    ${firefox-addons.youtube-shorts-block.addonId} = [ "*://*.youtube.com/*" "*://m.youtube.com/*" ];
  };
  extensionPreferences = pkgs.writeText "extension-preferences.json" (builtins.toJSON
    (lib.mapAttrs (_: origins: { permissions = [ ]; inherit origins; }) hostPermissions));

  addons = import ./extensions.nix firefox-addons;

  # Linked into the profile so a fresh one has them at first start;
  # policy installs only land after the window is up
  extensions = {
    force = true;
    packages = addons;
    settings = lib.mapAttrs (_: settings: { inherit settings; }) localSettings;
  };
in
{
  # Its restart after a crash inherits blocked crash signals, so every wasm
  # trap kills the process (bugzilla.mozilla.org/2075885)
  home.sessionVariables.MOZ_CRASHREPORTER_DISABLE = "1";

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = customLib.xdg.createMimes {
    browser = [ "firefox.desktop" ];
  };

  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPolicies = {
        # Installed from the store; AMO's `latest` URLs serve a bot check to VPN exits
        ExtensionSettings =
          { "*".installation_mode = "blocked"; }
          // lib.listToAttrs (map
            (addon: lib.nameValuePair addon.addonId {
              install_url = "file://${addon}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addon.addonId}.xpi";
              installation_mode = "force_installed";
            })
            addons);

        # Managed storage, which overrides the extensions' own settings
        "3rdparty".Extensions = {
          ${firefox-addons.ublock-origin.addonId}.adminSettings = builtins.readFile ./extension-settings/ublock.json;
          ${firefox-addons.privacy-badger.addonId}.showIntroPage = false;
          ${firefox-addons.bitwarden.addonId}.environment.base = "https://vault.coditon.com";
        };

        # No "Welcome to Firefox" on every fresh profile
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";

        # Trust CA cert for private services
        Certificates.Install = [
          "${../../../../../nixosConfigurations/vladof/services/certs/ca-cert.pem}"
        ];

        # Search engine
        SearchEngines = {
          Default = "searxng";
          Add = [{
            Name = "searxng";
            URLTemplate = "https://search.coditon.com/search?q={searchTerms}";
            Alias = "@sx";
          }];
        };

        # Bookmarks on toolbar, indexed by URL bar autocomplete
        Bookmarks = lib.concatLists (lib.mapAttrsToList
          (folder: items: map
            (item: { Title = item.name; URL = item.url; Folder = folder; Placement = "toolbar"; })
            items)
          (import ./bookmarks.nix));

        # All about:config settings as locked policies (baked into package)
        Preferences = lockPrefs ({
          # Behaviour
          "intl.accept_languages" = "en-US,en,fi";
          "browser.fullscreen.autohide" = false;
          "browser.startup.homepage" = "https://index.coditon.com";
          "browser.toolbars.bookmarks.visibility" = "never";
          "sidebar.revamp" = false;
          "browser.urlbar.suggest.bookmark" = true;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.recentsearches" = false;

          # Disable useless bloat
          "browser.tabs.firefox-view" = false;
          "browser.tabs.hoverPreview.enabled" = false;
          "identity.fxaccounts.enabled" = false;
          "layout.spellcheckDefault" = 2;
          "media.webspeech.synth.enabled" = false;
          "ui.key.menuAccessKeyFocuses" = false;

          # Remove AI garbage
          "browser.ml.enable" = false;
          "browser.ml.chat.enabled" = false;
          "browser.ml.chat.sidebar" = false;
          "extensions.ml.enabled" = false;
          "browser.ml.linkPreview.enabled" = false;
          "browser.tabs.groups.smart.enabled" = false;
          "browser.tabs.groups.smart.userEnabled" = false;
          "browser.translations.enable" = false;
          "browser.translations.automaticallyPopup" = false;
          "accessibility.alt_text.enabled" = false;

          # Appearance
          "browser.compactmode.show" = true;
          "browser.in-content.dark-mode" = true;
          "browser.uidensity" = 1;
          "extensions.activeThemeID" = "{7c4b7a20-26d8-4788-a840-71fa26d332e0}"; # gruvbox-medium-dark
          "font.name.monospace.x-western" = "${FONT}";
          "font.name.sans-serif.x-western" = "${FONT}";
          "font.name.serif.x-western" = "${FONT}";

          # Downloads
          "browser.download.dir" = config.xdg.userDirs.download;
          "browser.download.lastDir" = config.xdg.userDirs.download;
          "browser.download.folderList" = 2;

          # Ask for PNG/JPEG; content-negotiating CDNs then never serve WebP or AVIF
          "image.http.accept" = "image/png,image/jpeg,image/gif,image/svg+xml,image/*;q=0.8,*/*;q=0.5";
        }
        // (import ./hardened.nix));
      };
    };

    # Separate profiles for isolated cookies, logins, and history
    profiles = {
      personal = {
        id = 0;
        isDefault = true;
        inherit extensions;
      };
      work = {
        id = 1;
        inherit extensions;
      };
    };
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
      '')
    (lib.attrNames config.programs.firefox.profiles));
}
