{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      # Automatically allow direnv
      prefix = [ "/home/kari/Workspace" "/home/kari/nix-config" ];
    };
  };
}
