{ pkgs
, config
, inputs
, lib
, ...
}:
let
  user = "kari";
  optionalGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in
{
  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    initialPassword = "irak";
    extraGroups = optionalGroups [
      "acme"
      "adbusers"
      "audio"
      "caddy"
      "cups"
      "disk"
      "i2c"
      "input"
      "jackaudio"
      "libvirtd"
      "podman"
      "plugdev"
      "rtkit"
      "sftp"
      "sshd"
      "users"
      "vboxusers"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      # kari@phone (preferably removed, keep until YubiKey NFC for SSH is possible)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@trezor
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPSvwAIfx+2EYVbr9eC2imb5NJgpn36v6XAeofQjg5BEAAAABHNzaDo= kari@trezor"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOcS3prYIi5uC9LxscaKSYzyuF2Sh7f3I5V9s1sCWSc1AAAACXNzaDprYXJpMg== ssh:kari2"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = { };
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  # Allows access to flake inputs and custom packages
  home-manager.extraSpecialArgs = { inherit inputs pkgs; };

  # Move existing files rather than exiting with an error
  home-manager.backupFileExtension = "bak";

  home-manager.users."${user}" = {
    imports =
      [
        ./.config/direnv.nix
        ./.config/fish.nix
        ./.config/neovim.nix
        ./.config/tmux.nix
        ./.config/yazi.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths
        [ ../../hosts/${config.networking.hostName}/default.nix ];

    # Git
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      ignores = [
        ".knowledge"
        ".scripts"
        "TODO.md"
        "PROMPTS.md"
        "MEMO.md"
      ];
      settings = {
        alias = {
          uncommit = "reset --soft HEAD^";
        };
        safe.directory = [ "*" ];
        pull.rebase = true;
        http = {
          # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
          postBuffer = "524288000";
        };
      };
    };

    # Scripts and files
    home.sessionPath = [ "$HOME/.local/bin" ];
    home.file =
      let
        scriptDir = ./scripts;
        scriptFiles = builtins.readDir scriptDir;
        makeScript = name: {
          executable = true;
          target = ".local/bin/${name}";
          source = "${scriptDir}/${name}";
        };
      in
      builtins.mapAttrs (name: _: makeScript name) scriptFiles;

    # Default apps by user
    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
      FILEMANAGER = lib.mkDefault "yazi";
    };

    home.packages = with pkgs; [
      tt-utils
      ping-sweep
      eza
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "24.05";
  };
}
