{ lib
, pkgs
, config
, customLib
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
      extraPolicies.ExtensionSettings =
        {
          # Block non-declarative installing
          "*".installation_mode = "blocked";
        }
        // lib.listToAttrs (map
          (extension: {
            name = extension.uuid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${extension.shortId}/latest.xpi";
              installation_mode = "force_installed";
            };
          })
          (import ./extensions.nix));
    };

    profiles.personal = {
      isDefault = true;

      search = {
        default = "ddg";
        force = true;
        order = [ "ddg" "google" ];
      };

      bookmarks = {
        force = true;
        settings = import ./bookmarks.nix;
      };

      # about:config
      settings =
        {
          # Behaviour
          "browser.fullscreen.autohide" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.startup.homepage" = "https://index.coditon.com";
          "browser.toolbars.bookmarks.visibility" = "never"; # not working?
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.history" = false;

          # Disable useless bloat
          "browser.tabs.firefox-view" = false;
          "browser.tabs.hoverPreview.enabled" = false;
          "identity.fxaccounts.enabled" = false;
          "layout.spellcheckDefault" = 0;
          "media.webspeech.synth.enabled" = false;
          "ui.key.menuAccessKeyFocuses" = false;

          # Appearance
          "browser.compactmode.show" = true;
          "browser.in-content.dark-mode" = true;
          "browser.uidensity" = 1;
          "extensions.activeThemeID" = "{eb8c4a94-e603-49ef-8e81-73d3c4cc04ff}"; # https://addons.mozilla.org/en-US/firefox/addon/gruvbox-dark-theme/
          "font.name.monospace.x-western" = "${FONT}";
          "font.name.sans-serif.x-western" = "${FONT}";
          "font.name.serif.x-western" = "${FONT}";

          # Auto-translation
          "browser.translations.neverTranslateLanguages" = "en,fi";
          "browser.translations.alwaysTranslateLanguages" = "es,zh,ar,pt,id,fr,ja,ru,de,hi,et,sv,no,da";
          "browser.translations.autoTranslate" = true;
        }
        # derived from https://brainfucksec.github.io/firefox-hardening-guide
        // {
          # StartUp Settings
          "browser.aboutConfig.showWarning" = false;
          "browser.startup.page" = 1;

          # Disable Activity Stream
          "browser.newtabpage.enabled" = false;
          "browser.newtab.preload" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";

          # Geolocation
          "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
          "geo.provider.ms-windows-location" = false; # [Windows]
          "geo.provider.use_corelocation" = false; # [macOS]
          "geo.provider.use_gpsd" = false; # [Linux]
          "geo.provider.use_geoclue" = false; # [Linux]
          "browser.region.network.url" = "";
          "browser.region.update.enabled" = false;

          # Language / Locale
          "intl.accept_languages" = "en-US, en";
          "javascript.use_us_english_locale" = true; # HIDDEN PREF

          # Auto-updates / Recommendations
          "app.update.background.scheduling.enabled" = false; # [Windows]
          "app.update.auto" = false; # [Non-Windows]
          "extensions.getAddons.showPane" = false; # HIDDEN PREF
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.discovery.enabled" = false;

          # Telemetry
          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.enabled" = false; # [Default: false]
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true; # HIDDEN PREF
          "toolkit.coverage.opt-out" = true; # HIDDEN PREF
          "toolkit.coverage.endpoint.base" = "";
          "browser.ping-centre.telemetry" = false;
          "beacon.enabled" = false;

          # Studies
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";

          # Crash Reports
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;

          # Captive Portal Detection / Network Checks
          "captivedetect.canonicalURL" = "";
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;

          # Safe Browsing
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.phishing.enabled" = false;
          "browser.safebrowsing.blockedURIs.enabled" = false;
          "browser.safebrowsing.provider.google4.gethashURL" = "";
          "browser.safebrowsing.provider.google4.updateURL" = "";
          "browser.safebrowsing.provider.google.gethashURL" = "";
          "browser.safebrowsing.provider.google.updateURL" = "";
          "browser.safebrowsing.provider.google4.dataSharingURL" = "";
          "browser.safebrowsing.downloads.enabled" = false;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.safebrowsing.downloads.remote.url" = "";
          "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
          "browser.safebrowsing.downloads.remote.block_uncommon" = false;
          "browser.safebrowsing.allowOverride" = false;

          # Network: DNS, Proxy, IPv6
          "network.prefetch-next" = false;
          "network.dns.disablePrefetch" = true;
          "network.predictor.enabled" = false;
          "network.http.speculative-parallel-limit" = 0;
          "browser.places.speculativeConnect.enabled" = false;
          "network.dns.disableIPv6" = true;
          "network.gio.supported-protocols" = ""; # HIDDEN PREF
          "network.file.disable_unc_paths" = true; # HIDDEN PREF
          "permissions.manager.defaultsUrl" = "";
          "network.IDN_show_punycode" = true;

          # Search Bar: Suggestions, Autofill
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.fixup.alternate.enabled" = false;
          "browser.urlbar.trimURLs" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "browser.formfill.enable" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.available" = "off";
          "extensions.formautofill.creditCards.available" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "extensions.formautofill.heuristics.enabled" = false;
          "browser.urlbar.quicksuggest.scenario" = "history";
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;

          # Passwords
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.formlessCapture.enabled" = false;
          "network.auth.subresource-http-auth-allow" = 1;

          # Disk Cache / Memory
          "browser.cache.disk.enable" = false;
          "browser.sessionstore.privacy_level" = 2;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.pagethumbnails.capturing_disabled" = true; # HIDDEN PREF
          "browser.shell.shortcutFavicons" = false;
          "browser.helperApps.deleteTempFileOnExit" = true;

          # HTTPS / SSL/TLS / OSCP / CERTS
          "dom.security.https_only_mode" = false; # changed this
          "dom.security.https_only_mode_send_http_background_request" = false;
          "browser.xul.error_pages.expert_bad_cert" = true;
          "security.tls.enable_0rtt_data" = false;
          "security.OCSP.require" = true;
          "security.pki.sha1_enforcement_level" = 1;
          "security.cert_pinning.enforcement_level" = 2;
          "security.remote_settings.crlite_filters.enabled" = true;
          "security.pki.crlite_mode" = 2;

          # Headers / Referers
          "network.http.referer.XOriginPolicy" = 2;
          "network.http.referer.XOriginTrimmingPolicy" = 2;

          # Audio/Video: WebRTC, WebGL, DRM
          "media.peerconnection.enabled" = false;
          "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
          "media.peerconnection.ice.default_address_only" = true;
          "media.peerconnection.ice.no_host" = true;
          "webgl.disabled" = true;
          "media.autoplay.default" = 5;
          "media.eme.enabled" = true; # changed this

          # Downloads
          "browser.download.useDownloadDir" = false;
          "browser.download.manager.addToRecentDocs" = false;

          # Cookies
          "browser.contentblocking.category" = "strict";
          "privacy.partition.serviceWorkers" = true;
          "privacy.partition.always_partition_third_party_non_cookie_storage" = true;
          "privacy.partition.always_partition_third_party_non_cookie_storage.exempt_sessionstorage" = true;

          # UI Features
          "dom.disable_open_during_load" = true;
          "dom.popup_allowed_events" = "click dblclick mousedown pointerdown";
          "extensions.pocket.enabled" = false;
          "extensions.Screenshots.disabled" = true;
          "pdfjs.enableScripting" = false;
          "privacy.userContext.enabled" = true;

          # Extensions
          "extensions.enabledScopes" = 5;
          "extensions.webextensions.restrictedDomains" = "";
          "extensions.postDownloadThirdPartyPrompt" = false;

          # Shutdown settings
          "network.cookie.lifetimePolicy" = 0; # changed this
          "privacy.sanitize.sanitizeOnShutdown" = true;
          "privacy.clearOnShutdown.cache" = true;
          "privacy.clearOnShutdown.cookies" = false; # changed this
          "privacy.clearOnShutdown.downloads" = true;
          "privacy.clearOnShutdown.formdata" = true;
          "privacy.clearOnShutdown.history" = true;
          "privacy.clearOnShutdown.offlineApps" = true;
          "privacy.clearOnShutdown.sessions" = true;
          "privacy.clearOnShutdown.sitesettings" = false;
          "privacy.sanitize.timeSpan" = 0;

          # Fingerprinting (RFP)
          "privacy.resistFingerprinting" = false; # changed this
          "privacy.window.maxInnerWidth" = 1600;
          "privacy.window.maxInnerHeight" = 900;
          "privacy.resistFingerprinting.block_mozAddonManager" = true;
          "browser.display.use_system_colors" = false; # Default: false [Non-Windows]
          "browser.startup.blankWindow" = false;
        };
    };
  };
}
