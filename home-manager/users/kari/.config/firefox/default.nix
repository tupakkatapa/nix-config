{ pkgs
, config
, customLib
, mozid
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;
in
{
  # If the browser doesn’t retain cookies or add-on settings between reboots, despite a persistent '~/.mozilla', go to 'about:profiles' and select 'Restart normally...'

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = customLib.xdg.createMimes {
    browser = [ "firefox.desktop" ];
  };

  programs.firefox = {
    enable = true;
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
      };
    };

    profiles =
      let
        search = {
          default = "searxng";
          force = true;
          order = [ "searxng" "ddg" "google" ];
          engines = {
            "searxng" = {
              urls = [{ template = "https://search.coditon.com/search?q={searchTerms}"; }];
              definedAliases = [ "@sx" ];
            };
          };
        };

        bookmarks = {
          force = true;
          settings = import ./bookmarks.nix;
        };

        # about:config
        settings = {
          # Behaviour
          "browser.fullscreen.autohide" = false;
          "browser.startup.homepage" = "https://index.coditon.com";
          "browser.toolbars.bookmarks.visibility" = "never"; # not working?
          "sidebar.revamp" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.history" = false;

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
          "extensions.ml.enabled" = false;
          "browser.ml.linkPreview.enabled" = false;
          "browser.tabs.groups.smart.enabled" = false;
          "browser.tabs.groups.smart.userEnabled" = false;

          # Appearance
          "browser.compactmode.show" = true;
          "browser.in-content.dark-mode" = true;
          "browser.uidensity" = 1;
          "extensions.activeThemeID" = "{eb8c4a94-e603-49ef-8e81-73d3c4cc04ff}"; # https://addons.mozilla.org/en-US/firefox/addon/gruvbox-dark-theme/
          "font.name.monospace.x-western" = "${FONT}";
          "font.name.sans-serif.x-western" = "${FONT}";
          "font.name.serif.x-western" = "${FONT}";
        }
        // (import ./hardened.nix);
      in
      {
        personal = {
          id = 0;
          isDefault = true;
          inherit search bookmarks settings;
        };
        work = {
          id = 1;
          inherit search bookmarks settings;
        };
      };
  };
}
