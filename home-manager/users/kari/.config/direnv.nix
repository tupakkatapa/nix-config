{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Automatically allow direnv
    config.whitelist.prefix = [
      "/mnt/sftp/code/workspace" # clients
      "/mnt/wd-red/sftp/code/workspace" # vladof
    ];
  };
}
