{
  inputs,
  outputs,
  nixpkgs,
  config,
  lib,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    coc.enable = true;
    coc.settings = {
      "languageserver" = {
        nix = {
          command = "nil";
          filetypes = ["nix"];
          rootPatterns = ["flake.nix"];
        };
      };
    };
    defaultEditor = true;
    extraPackages = with pkgs; [
      nil
    ];
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = false;
        max_line_width = 78;
        indent_style = "space";
        indent_size = 2;
      };
    };
  };
}
