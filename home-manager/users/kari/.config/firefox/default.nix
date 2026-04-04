{ pkgs
, lib
, config
, customLib
, mozid
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;

  # Convert about:config prefs to policy format
  lockPrefs = builtins.mapAttrs (_: value: { Value = value; Status = "locked"; });
in
{
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = customLib.xdg.createMimes {
    browser = [ "firefox.desktop" ];
  };

  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPolicies = {
        ExtensionSettings =
          { "*".installation_mode = "blocked"; }
          # https://github.com/tupakkatapa/mozid
          // mozid.lib.mkExtensions (import ./extensions.nix);

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
        }
        // (import ./hardened.nix));
      };
    };

    # Separate profiles for isolated cookies, logins, and history
    profiles = {
      personal = {
        id = 0;
        isDefault = true;
      };
      work = {
        id = 1;
      };
    };
  };
}
