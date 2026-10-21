{ config
, lib
, ...
}:
let
  user = "kari";
  hasOllama = config.services.ollama.enable;
  ollamaUrl = if hasOllama then "http://localhost:11434" else "https://chat.coditon.com/";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  age.secrets = {
    "nix-access-tokens" = {
      rekeyFile = ./secrets/nix-access-tokens.age;
      owner = user;
    };
  };

  # Append access tokens to nix.conf to avoid rate limits
  nix.extraOptions = ''
    !include ${config.age.secrets.nix-access-tokens.path}
  '';

  # Trust fleet host keys for non-interactive SSH/SFTP
  services.openssh.knownHosts = {
    vladof = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w";
      extraHostNames = [ "10.42.0.8" ];
    };
    torgue = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B";
      extraHostNames = [ "10.42.0.7" ];
    };
    hyperion = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXTPhVIrcmsJp9AwrPGfh3bX4Ixq6NmwTve3ExlLp16";
      extraHostNames = [ "10.42.0.1" ];
    };
    maliwan = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcbYE9n5NE8EhxIrlR9tc4ZredoxvTPubQniNGQWH+s";
      extraHostNames = [ "10.42.0.9" "172.16.16.3" ];
    };
  };

  home-manager.users."${user}" = {
    imports = [
      ./.config/claude
      ./.config/yazi.nix
    ];

    # Extra SSH config
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          # Without reuse every connection costs a PIN and a touch
          ControlMaster = "auto";
          ControlPath = "/run/user/%i/ssh-%C";
          ControlPersist = "10m";

          # Notice a dead tunnel in ~45s instead of hanging
          ServerAliveInterval = 15;
          ServerAliveCountMax = 3;
        };
        "hyperion" = {
          User = "core";
          HostName = "10.42.0.1";
          ForwardAgent = true;
        };
        "torgue" = {
          HostName = "10.42.0.7";
          ForwardAgent = true;
        };
        "vladof" = {
          HostName = "10.42.0.8";
          ForwardAgent = true;
        };
        # 10.42.0.9 is leased to the wired MAC, so the tunnel address is stable
        "maliwan" = {
          HostName = "172.16.16.3";
          ForwardAgent = true;
        };
        "maliwan-lan" = {
          HostName = "10.42.0.9";
          ForwardAgent = true;
        };
        "10.42.0.*".StrictHostKeyChecking = "no";
      };
    };

    # Git identity
    programs.git.settings.user = {
      email = "jesse@ponkila.com";
      name = "Jesse Karjalainen";
    };
    programs.git.signing = {
      format = "ssh";
      # Literal pubkey resolves through the agent, forwarded or local
      key = lib.mkDefault "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp";
      signByDefault = true;
    };
    programs.git.settings.gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    home.file.".ssh/allowed_signers".text = lib.concatLines [
      "jesse@ponkila.com namespaces=\"git\" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPSvwAIfx+2EYVbr9eC2imb5NJgpn36v6XAeofQjg5BEAAAABHNzaDo= kari@trezor"
      "jesse@ponkila.com namespaces=\"git\" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
      "jesse@ponkila.com namespaces=\"git\" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOcS3prYIi5uC9LxscaKSYzyuF2Sh7f3I5V9s1sCWSc1AAAACXNzaDprYXJpMg== ssh:kari2"
    ];

    home.sessionVariables = {
      OLLAMA_URL = ollamaUrl;
      SEARXNG_URL = "https://search.coditon.com";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
    };
  };
}
