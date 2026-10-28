{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Automatically allow direnv
    config.whitelist.prefix = [ "/home/kari/Workspace" ];
    # Host-local cache: the workspace is shared, the links point into one host's store
    stdlib = ''
      direnv_layout_dir() {
        echo "''${XDG_CACHE_HOME:-$HOME/.cache}/direnv/layouts/$(echo -n "$PWD" | sha1sum | cut -d" " -f1)"
      }
    '';
  };
}
