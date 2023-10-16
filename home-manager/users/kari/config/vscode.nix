{
  pkgs,
  config,
  ...
}: let
  inherit (config.home.sessionVariables) FONT;
in {
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/plain" = ["codium.desktop"];
  };

  programs.vscode = let
    disableKeys = keysList:
      map (keyName: {
        key = keyName;
        command = "";
      })
      keysList;
  in {
    enable = true;
    package = pkgs.vscodium;
    # If the extensions don't load correctly, you probably have installed some extensions ad hoc
    # In that case, comment these out, rebuild and uninstall any extensions if there are any
    extensions = with pkgs.vscode-extensions;
      [
        bbenoist.nix
        timonwong.shellcheck
        dart-code.flutter
        rust-lang.rust-analyzer
        jdinhlife.gruvbox
        vscodevim.vim
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "markdown-preview-github-styles";
          publisher = "bierner";
          version = "2.0.2";
          sha256 = "sha256-GiSS9gCCmOfsBrzahJe89DfyFyJJhQ8tkXVJbfibHQY=";
        }
      ];
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    userSettings = {
      "editor.cursorBlinking" = "phase";
      "editor.cursorSmoothCaretAnimation" = true;
      "editor.cursorSurroundingLines" = 15;
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
      "terminal.integrated.fontFamily" = "${FONT}";
      "window.menuBarVisibility" = "toggle";
      "workbench.colorTheme" = "Gruvbox Dark Medium";
      "editor.lineNumbers" = "relative";
      "vim.useSystemClipboard" = true;
    };
    keybindings = disableKeys ["Up" "Down" "Right" "Left"];
  };
}
