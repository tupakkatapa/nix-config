{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Automatically allow direnv
    config.whitelist.prefix = [ "/home/kari/Workspace" "/home/kari/nix-config" ];
  };
}
