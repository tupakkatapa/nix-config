{ pkgs }:
pkgs.mkYarnPackage {
  name = "foo";
  version = "0.1.0";

  src = ./.;
  packageJSON = ./package.json;
  yarnLock = ./yarn.lock;
}

