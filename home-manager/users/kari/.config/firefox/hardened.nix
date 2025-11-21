# Derived from https://brainfucksec.github.io/firefox-hardening-guide-2024#userjs
{
  # Startup settings
  "browser.aboutConfig.showWarning" = false;
  "browser.startup.page" = 1;
  # "browser.startup.homepage" = "about:home";
  "browser.newtabpage.enabled" = false;
  "browser.newtabpage.activity-stream.showSponsored" = false;
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
  "browser.newtabpage.activity-stream.default.sites" = "";

  # Geolocation
  "geo.provider.ms-windows-location" = false;
  "geo.provider.use_corelocation" = false;
  "geo.provider.use_geoclue" = false;

  # Language / Locale
  "intl.accept_languages" = "en-US, en";
  "javascript.use_us_english_locale" = true;

  # Recommendations
  "extensions.getAddons.showPane" = false;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "browser.discovery.enabled" = false;

  # Telemetry
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry" = false;
  "datareporting.policy.dataSubmissionEnabled" = false;
  "datareporting.healthreport.uploadEnabled" = false;
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  "toolkit.telemetry.updatePing.enabled" = false;
  "toolkit.telemetry.bhrPing.enabled" = false;
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  "toolkit.telemetry.coverage.opt-out" = true;
  "toolkit.coverage.opt-out" = true;
  "toolkit.coverage.endpoint.base" = "";

  # Studies
  "app.shield.optoutstudies.enabled" = false;
  "app.normandy.enabled" = false;
  "app.normandy.api_url" = "";

  # Creash Reports
  "breakpad.reportURL" = "";
  "browser.tabs.crashReporting.sendReport" = false;

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

  # Network: DNS, Proxy, Network Checks
  "network.prefetch-next" = false;
  "network.dns.disablePrefetch" = true;
  "network.dns.disablePrefetchFromHTTPS" = true;
  "network.predictor.enabled" = false;
  "network.http.speculative-parallel-limit" = 0;
  "browser.places.speculativeConnect.enabled" = false;
  "network.gio.supported-protocols" = "";
  "network.file.disable_unc_paths" = true;
  "permissions.manager.defaultsUrl" = "";
  "network.IDN_show_punycode" = true;
  "captivedetect.canonicalURL" = "";
  "network.captive-portal-service.enabled" = false;
  "network.connectivity-service.enabled" = false;

  # Search Bar: Suggestiongs, Autofill, Forms
  "browser.urlbar.speculativeConnect.enabled" = false;
  "browser.urlbar.quicksuggest.enabled" = false;
  "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
  "browser.urlbar.suggest.quicksuggest.sponsored" = false;
  "browser.search.suggest.enabled" = false;
  "browser.urlbar.suggest.searches" = false;
  "browser.urlbar.trending.featureGate" = false;
  "browser.urlbar.addons.featureGate" = false;
  "browser.urlbar.mdn.featureGate" = false;
  "browser.urlbar.yelp.featureGate" = false;
  "browser.formfill.enable" = false;
  "extensions.formautofill.addresses.enabled" = false;
  "extensions.formautofill.creditCards.enabled" = false;

  # Passwords
  "signon.rememberSignons" = false;
  "signon.autofillForms" = false;
  "signon.formlessCapture.enabled" = false;
  "network.auth.subresource-http-auth-allow" = 1;

  # Disk Cache / Memory
  "browser.cache.disk.enable" = false;
  "browser.privatebrowsing.forceMediaMemoryCache" = true;
  "media.memory_cache_max_size" = 65536;
  "browser.sessionstore.privacy_level" = 2;
  "browser.sessionstore.resume_from_crash" = false;
  "toolkit.winRegisterApplicationRestart" = false;
  "browser.shell.shortcutFavicons" = false;
  "browser.pagethumbnails.capturing_disabled" = true;
  "browser.download.start_downloads_in_tmp_dir" = true;
  "browser.helperApps.deleteTempFileOnExit" = true;

  # HTTPS (SSL/TLS, OSC, Certs)
  "security.tls.enable_0rtt_data" = false;
  "security.OCSP.require" = true;
  "browser.xul.error_pages.expert_bad_cert" = true;
  "security.cert_pinning.enforcement_level" = 2;
  "security.remote_settings.crlite_filters.enabled" = true;
  "security.pki.crlite_mode" = 2;
  "dom.security.https_only_mode" = true;
  "dom.security.https_only_mode_send_http_background_request" = false;

  # Headers / Referers
  "network.http.referer.XOriginTrimmingPolicy" = 2;

  # Audio/Video: WebRTC, WebGL
  # "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
  # "media.peerconnection.ice.default_address_only" = true;
  # "media.peerconnection.ice.no_host" = true;
  # "webgl.disabled" = true;

  # Downloads
  "browser.download.useDownloadDir" = false;
  "browser.download.manager.addToRecentDocs" = false;
  "browser.download.always_ask_before_handling_new_types" = true;

  # Cookies
  "browser.contentblocking.category" = "strict";

  # UI Features
  "dom.popup_allowed_events" = "click dblclick mousedown pointerdown";
  "pdfjs.enableScripting" = false;
  "privacy.userContext.enabled" = true;
  "privacy.userContext.ui.enabled" = true;

  # Extensions
  "extensions.enabledScopes" = 5;
  "extensions.postDownloadThirdPartyPrompt" = false;

  # Shutdown Settings & Sanitizing
  "privacy.sanitize.sanitizeOnShutdown" = true;
  # "privacy.clearOnShutdown.cookies" = true;
  "privacy.clearOnShutdown.offlineApps" = true;
  # "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
  "privacy.clearOnShutdown_v2.downloads" = true;
  "privacy.clearOnShutdown_v2.formdata" = true;
  "privacy.sanitize.timeSpan" = 0;

  # Fingerprinting (RFP)
  # "privacy.resistFingerprinting" = true;
  "privacy.window.maxInnerWidth" = 1600;
  "privacy.window.maxInnerHeight" = 900;
  "privacy.resistFingerprinting.letterboxing" = false;
  "privacy.resistFingerprinting.block_mozAddonManager" = true;
  "privacy.spoof_english" = 1;
  "browser.display.use_system_colors" = false;
  "widget.non-native-theme.use-theme-accent" = false;
  "browser.link.open_newwindow.restriction" = 0;
}

