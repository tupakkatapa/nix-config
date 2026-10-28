{ pkgs
, lib
, config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;

  # Convert about:config prefs to policy format
  lockPrefs = builtins.mapAttrs (_: value: { Value = value; Status = "locked"; });

  inherit (pkgs) firefox-addons;

  addons = import ./extensions.nix firefox-addons;

  # Linked into the profile so a fresh one has them at first start;
  # policy installs only land after the window is up
  extensions = {
    force = true;
    packages = addons;
  };
in
{
  imports = [ ./site-data.nix ];

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

        # Every fresh profile would ask again
        Permissions = {
          Notifications.Allow = [
            "https://web.telegram.org"
            "https://web.whatsapp.com"
            "https://app.slack.com"
            "https://meet.google.com"
            "https://calendar.google.com"
            "https://mail.google.com"
            "https://discord.com"
            "https://linear.app"
            "https://element.coditon.com"
          ];
          Camera.Allow = [ "https://meet.google.com" ];
          Microphone.Allow = [ "https://meet.google.com" ];
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

          # DRM: Firefox fetches Widevine on first use
          "media.eme.enabled" = true;
          "media.gmp-widevinecdm.enabled" = true;

          # Disable useless bloat
          "browser.tabs.firefox-view" = false;
          "browser.tabs.hoverPreview.enabled" = false;
          "identity.fxaccounts.enabled" = false;
          "identity.fxaccounts.toolbar.enabled" = false;
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

    profiles.personal = {
      id = 0;
      isDefault = true;
      inherit extensions;
    };
  };
}
