{
  outputs,
  inputs,
}: {
  # Adds my custom packages
  additions = final: prev: import ./packages {pkgs = final;};

  # Modifies existing packages
  modifications = final: prev: {};
}
