{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      timonwong.shellcheck
    ];
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
