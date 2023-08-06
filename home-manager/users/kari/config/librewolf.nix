{
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    BROWSER = lib.mkDefault "librewolf";
  };

  # https://librewolf.net/docs/faq/#cant-open-links-with-librewolf-when-using-wayland
  home.file = {
    ".local/share/applications/librewolf.desktop".source = "${pkgs.librewolf}/share/applications/librewolf.desktop";
  };

  xdg.mimeApps = lib.mkIf (pkgs.system != "aarch64-darwin" && pkgs.system != "x86_64-darwin") {
    enable = true;
    defaultApplications = {
      "text/html" = ["librewolf.desktop"];
      "text/xml" = ["librewolf.desktop"];
      "x-scheme-handler/http" = ["librewolf.desktop"];
      "x-scheme-handler/https" = ["librewolf.desktop"];
    };
  };

  programs.librewolf = {
    enable = true;
    settings = {
      "browser.disableResetPrompt" = true;
      "browser.download.panel.shown" = true;
      "browser.download.useDownloadDir" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.shell.checkDefaultBrowser" = false;
      "browser.shell.defaultBrowserCheckCount" = 1;
      "browser.startup.homepage" = "https://start.duckduckgo.com";
      "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":18,"newElementCount":4}'';
      "dom.security.https_only_mode" = true;
      "identity.fxaccounts.enabled" = false;
      "privacy.trackingprotection.enabled" = true;
      "signon.rememberSignons" = false;
      "font.name.serif.x-western" = "JetBrains Mono";
      "extensions.activeThemeID" = "{eb8c4a94-e603-49ef-8e81-73d3c4cc04ff}";
    };
  };
}
