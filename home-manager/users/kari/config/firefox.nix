{
  lib,
  inputs,
  pkgs,
  config,
  ...
}: let
  inherit (config.home.sessionVariables) FONT;
  # Allow access to flake inputs with 'home-manager.extraSpecialArgs = { inherit inputs; };'
  addons = inputs.firefox-addons.packages.${pkgs.system};
in {
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = ["firefox.desktop"];
    "text/xml" = ["firefox.desktop"];
    "x-scheme-handler/http" = ["firefox.desktop"];
    "x-scheme-handler/https" = ["firefox.desktop"];
    "x-scheme-handler/about" = ["firefox.desktop"];
    "x-scheme-handler/unknown" = ["firefox.desktop"];
  };

  programs.firefox = {
    enable = true;
    profiles.personal = {
      isDefault = true;

      extensions = with addons; [
        ublock-origin
        bitwarden
        sponsorblock
        torrent-control
        darkreader
        youtube-shorts-block
        ff2mpv
        privacy-badger
      ];

      search = {
        default = "DuckDuckGo";
        force = true;
        order = [
          "DuckDuckGo"
          "Google"
        ];
      };

      settings = {
        "browser.compactmode.show" = true;
        "browser.fullscreen.autohide" = false;
        "browser.search.openintab" = true;
        "browser.search.widget.inNavBar" = true;
        "browser.startup.homepage" = "https://start.duckduckgo.com";
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.uidensity" = 1;
        "extensions.activeThemeID" = "{eb8c4a94-e603-49ef-8e81-73d3c4cc04ff}";
        "font.name.serif.x-western" = "${FONT}";
        "font.name.monospace.x-western" = "${FONT}";
        "font.name.sans-serif.x-western" = "${FONT}";
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };

    package = with pkgs;
      wrapFirefox firefox-unwrapped {
        extraNativeMessagingHosts = lib.optional config.programs.mpv.enable pkgs.ff2mpv;
        extraPolicies = {
          AppAutoUpdate = false;
          CaptivePortal = false;
          DisableAppUpdate = true;
          DisableFirefoxAccounts = true;
          DisableFirefoxStudies = true;
          DisableFormHistory = true;
          DisableMasterPasswordCreation = true;
          DisablePocket = true;
          DisableSetDesktopBackground = true;
          DisableTelemetry = true;
          DisplayBookmarksToolbar = "always";
          DontCheckDefaultBrowser = true;
          EnableTrackingProtection = true;
          FirefoxHome = {
            Highlights = false;
            Pocket = false;
            Snippets = false;
            SponsporedPocket = false;
            SponsporedTopSites = false;
          };
          NoDefaultBookmarks = true;
          OfferToSaveLoginsDefault = false;
          PasswordManagerEnabled = false;
          PromptForDownloadLocation = true;
          SanitizeOnShutdown = {
            Cache = true;
            History = true;
            Cookies = false;
            Downloads = true;
            FormData = true;
            Sessions = true;
            OfflineApps = true;
          };
          UserMessaging = {
            ExtensionRecommendations = false;
            SkipOnboarding = true;
          };
          UseSystemPrintDialog = true;

          # https://github.com/arkenfox/user.js/wiki/
          Preferences = {
            "accessibility.force_disabled" = 1;
            "app.normandy.api_url" = "";
            "app.normandy.enabled" = false;
            "app.shield.optoutstudies.enabled" = false;
            "app.update.background.scheduling.enabled" = false;
            "beacon.enabled" = false;
            "breakpad.reportURL" = "";
            "browser.aboutConfig.showWarning" = false;
            "browser.cache.disk.enable" = false;
            "browser.contentblocking.category" = "strict";
            "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
            "browser.discovery.enabled" = false;
            "browser.display.use_system_colors" = false;
            "browser.download.alwaysOpenPanel" = false;
            "browser.download.always_ask_before_handling_new_types" = true;
            "browser.download.manager.addToRecentDocs" = false;
            "browser.download.useDownloadDir" = false;
            "browser.fixup.alternate.enabled" = false;
            "browser.formfill.enable" = false;
            "browser.helperApps.deleteTempFileOnExit" = true;
            "browser.link.open_newwindow" = 3;
            "browser.link.open_newwindow.restriction" = 0;
            "browser.messaging-system.whatsNewPanel.enabled" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.newtabpage.enabled" = false;
            "browser.pagethumbnails.capturing_disabled" = true;
            "browser.ping-centre.telemetry" = false;
            "browser.places.speculativeConnect.enabled" = false;
            "browser.privatebrowsing.forceMediaMemoryCache" = true;
            "browser.region.network.url" = "";
            "browser.region.update.enabled" = false;
            "browser.safebrowsing.downloads.remote.enabled" = false;
            "browser.search.suggest.enabled" = false;
            "browser.sessionstore.privacy_level" = 2;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.shell.shortcutFavicons" = false;
            "browser.ssl_override_behavior" = 1;
            "browser.startup.blankWindow" = false;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.startup.page" = 1;
            "browser.tabs.crashReporting.sendReport" = false;
            "browser.uitour.enabled" = false;
            "browser.uitour.url" = "";
            "browser.urlbar.dnsResolveSingleWordsAfterSearch" = 0;
            "browser.urlbar.speculativeConnect.enabled" = false;
            "browser.urlbar.suggest.quicksuggest" = false;
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.suggest.searches" = false;
            "browser.xul.error_pages.expert_bad_cert" = true;
            "captivedetect.canonicalURL" = "";
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "devtools.chrome.enabled" = false;
            "devtools.debugger.remote-enabled" = false;
            "dom.disable_beforeunload" = true;
            "dom.disable_open_during_load" = true;
            "dom.disable_window_move_resize" = true;
            "dom.popup_allowed_events" = "click dblclick mousedown pointerdown";
            "dom.security.https_only_mode" = true;
            "dom.security.https_only_mode_send_http_background_request" = false;
            "dom.storage.next_gen" = true;
            "extensions.autoDisableScopes" = 15;
            "extensions.blocklist.enabled" = true;
            "extensions.enabledScopes" = 5;
            "extensions.getAddons.showPane" = false;
            "extensions.htmlaboutaddons.recommendations.enabled" = false;
            "extensions.postDownloadThirdPartyPrompt" = false;
            "extensions.webcompat-reporter.enabled" = false;
            "extensions.webcompat.enable_shims" = true;
            "geo.enabled" = false;
            "geo.provider.use_corelocation" = false;
            "geo.provider.use_geoclue" = false;
            "geo.provider.use_gpsd" = false;
            "intl.accept_languages" = "en-US = en";
            "javascript.use_us_english_locale" = true;
            "keyword.enabled" = true;
            "media.eme.enabled" = true;
            "media.memory_cache_max_size" = 65536;
            "media.peerconnection.ice.default_address_only" = true;
            "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
            "middlemouse.contentLoadURL" = false;
            "network.IDN_show_punycode" = true;
            "network.auth.subresource-http-auth-allow" = 1;
            "network.captive-portal-service.enabled" = false;
            "network.connectivity-service.enabled" = false;
            "network.cookie.lifetimePolicy" = 0;
            "network.dns.disableIPv6" = true;
            "network.dns.disablePrefetch" = true;
            "network.file.disable_unc_paths" = true;
            "network.gio.supported-protocols" = "";
            "network.http.referer.XOriginPolicy" = 0;
            "network.http.referer.XOriginTrimmingPolicy" = 2;
            "network.http.referer.spoofSource" = false;
            "network.http.speculative-parallel-limit" = 0;
            "network.predictor.enable-prefetch" = false;
            "network.predictor.enabled" = false;
            "network.prefetch-next" = false;
            "network.protocol-handler.external.ms-windows-store" = false;
            "network.proxy.socks_remote_dns" = true;
            "pdfjs.disabled" = false;
            "pdfjs.enableScripting" = false;
            "permissions.delegation.enabled" = false;
            "permissions.manager.defaultsUrl" = "";
            "privacy.cpd.cache" = true;
            "privacy.cpd.cookies" = false;
            "privacy.cpd.formdata" = true;
            "privacy.cpd.history" = true;
            "privacy.cpd.offlineApps" = false;
            "privacy.cpd.sessions" = true;
            "privacy.firstparty.isolate" = false;
            "privacy.partition.always_partition_third_party_non_cookie_storage" = true;
            "privacy.partition.always_partition_third_party_non_cookie_storage.exempt_sessionstorage" = false;
            "privacy.partition.serviceWorkers" = true;
            "privacy.resistFingerprinting" = true;
            "privacy.resistFingerprinting.block_mozAddonManager" = true;
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;
            "privacy.window.maxInnerHeight" = 900;
            "privacy.window.maxInnerWidth" = 1600;
            "security.OCSP.enabled" = 1;
            "security.OCSP.require" = true;
            "security.ask_for_password" = 2;
            "security.cert_pinning.enforcement_level" = 2;
            "security.csp.enable" = true;
            "security.dialog_enable_delay" = 1000;
            "security.family_safety.mode" = 0;
            "security.mixed_content.block_display_content" = true;
            "security.password_lifetime" = 5;
            "security.pki.crlite_mode" = 2;
            "security.pki.sha1_enforcement_level" = 1;
            "security.remote_settings.crlite_filters.enabled" = true;
            "security.ssl.require_safe_negotiation" = true;
            "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            "security.tls.enable_0rtt_data" = false;
            "security.tls.version.enable-deprecated" = false;
            "signon.autofillForms" = false;
            "signon.formlessCapture.enabled" = false;
            "toolkit.coverage.endpoint.base" = "";
            "toolkit.coverage.opt-out" = true;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.server" = "data: =";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "toolkit.winRegisterApplicationRestart" = false;
            "webchannel.allowObject.urlWhitelist" = "";
            "webgl.disabled" = false;
            "widget.non-native-theme.enabled" = true;
          };
        };
      };
  };
}
