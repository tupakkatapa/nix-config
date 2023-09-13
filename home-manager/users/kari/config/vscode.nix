{pkgs, ...}: {
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/plain" = ["codium.desktop"];
  };

  programs.vscode = {
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
        tyriar.sort-lines
        jdinhlife.gruvbox
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
      "terminal.integrated.fontFamily" = "JetBrains Mono";
      "window.menuBarVisibility" = "toggle";
      "workbench.colorTheme" = "Gruvbox Dark Medium";
    };
  };
}
