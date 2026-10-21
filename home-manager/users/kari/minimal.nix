{ pkgs
, config
, inputs
, ...
}:
let
  user = "kari";

  optionalGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in
{
  # Trust vladof's CA cert for private services
  security.pki.certificateFiles = [
    ../../../nixosConfigurations/vladof/services/certs/ca-cert.pem
  ];

  # Set password
  # echo "password" | mkpasswd -s
  age.secrets."password".rekeyFile = ./secrets/password.age;

  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    hashedPasswordFile = config.age.secrets.password.path;
    extraGroups = optionalGroups [
      "adbusers"
      "audio"
      "cups"
      "i2c"
      "jackaudio"
      "libvirtd"
      "podman"
      "plugdev"
      "rtkit"
      "sftp"
      "sshd"
      "transmission"
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

      # kari@3ds
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy/Zj1ft5IHaQ8/eg5BNu7Z4x3NfepyPR7b0WWasoCsnpz4RRvXRm91ATO4QfyHdvKEzoqfkyHFQ2YNhfm3HkreOomUARN6UGnvA11RfyWIjoC2pGqH0JOEQMOstsdqDcAxPkXRPPBUCLbMIXkwOpDVp67jc9Qo2bBNmqzCMGtTxdOlkqF2bxT7rm0RzsQ5F9KTfBfxqmfW/3SThelH4pH8I9bjeKLtEz9uOEllI9GKRdU71ADbrh88paSCi29idLXwMyfsT0qh9MGqmRvdgNWvYEkhlKbg/OmPYBX2SGarQZ4umJWWQsDai4qbNAu310XQDR38AbqWo8xWd6pS9tB kari@3ds"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = { };

  # sudo accepts a signature from the agent, so a YubiKey touch replaces the password
  security.pam.rssh = {
    enable = true;
    settings.auth_key_file = "/etc/ssh/authorized_keys.d/\${user}";
  };
  security.pam.services.sudo.rssh = true;
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
        ./.config/git.nix
        ./.config/neovim.nix
        ./.config/tmux.nix
      ]
      # Importing host-specific home-manager config if it exists
      ++ optionalPaths
        [ ../../hosts/${config.networking.hostName}/default.nix ];

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
      THEME = "gruvbox-dark-medium";
    };

    home.packages = with pkgs; [
      eza
      isd
      ping-sweep
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "24.05";
  };
}
