{pkgs, ...}: {
  xdg.mimeApps.defaultApplications = {
    "text/plain" = ["codium.desktop"];
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions =
      with pkgs.vscode-extensions; [
        bbenoist.nix
        timonwong.shellcheck
        dart-code.flutter
        rust-lang.rust-analyzer
      ]
      # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #   {
      #     name = "rainbow-brackets-2";
      #     publisher = "tejasvi";
      #     version = "1.1.0";
      #     sha256 = "sha256-07ZIZD8Bt1Z1hhs+AM2LYSEFMNRqjZFog6H0bGqblLs=";
      #   }
      # ]
      ;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    userSettings = {
      "editor.cursorBlinking" = "phase";
      "editor.cursorSmoothCaretAnimation" = true;
      "editor.cursorSurroundingLines" = 15;
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
      "terminal.integrated.fontFamily" = "JetBrains Mono";
    };
  };
}
