let
  # Users
  kari = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torgue";
  kariPath = "home-manager/users/kari/secrets";

  # Systems
  torgue = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B root@torgue";
  vladof = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w root@vladof";
  vladofPath = "nixosConfigurations/vladof/secrets";
  allSystems = [ torgue vladof ];
in
{
  # Kari
  "${kariPath}/ed25519-sk.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/password.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/wg-dinar.age".publicKeys = allSystems ++ [ kari ];
  "${kariPath}/yubico-u2f-keys.age".publicKeys = allSystems ++ [ kari ];

  # Vladof
  "${vladofPath}/acme-cf-dns-token.age".publicKeys = [ kari vladof ];
  "${vladofPath}/lanraragi-admin-password.age".publicKeys = [ kari vladof ];
  "${vladofPath}/vaultwarden-env.age".publicKeys = [ kari vladof ];
}
