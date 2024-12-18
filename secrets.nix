let
  # Users
  kari = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torgue";
  kariPath = "home-manager/users/kari/secrets";

  # Systems
  torgue = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B root@torgue";
  vladof = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w root@vladof";
  maliwan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcbYE9n5NE8EhxIrlR9tc4ZredoxvTPubQniNGQWH+s root@maliwan";
  vladofPath = "nixosConfigurations/vladof/secrets";
  allSystems = [ torgue vladof maliwan ];
in
{
  # Kari
  "${kariPath}/ed25519-sk.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/password.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/wg-dinar.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/wg-home.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/wpa-psk.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/yubico-u2f-keys.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/openai-api-key.age".publicKeys = allSystems ++ [ kari ];

  # Vladof
  "${vladofPath}/acme-cf-dns-token.age".publicKeys = [ kari vladof ];
  "${vladofPath}/vaultwarden-env.age".publicKeys = [ kari vladof ];
  "${vladofPath}/kavita-token.age".publicKeys = [ kari vladof ];
}
