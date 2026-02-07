{ pkgs
, containerConfig
, inputs
, globalContainerConfig
, dataDir
, ...
}:
let
  # Define the derivation for blog contents
  blogContents = pkgs.runCommand "blog-contents" { } ''
    mkdir -p $out
    cp -r ${./contents}/* $out
  '';
  uid = builtins.toString containerConfig.molesk.uid;
in
{
  containers.molesk = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.molesk) hostAddress localAddress;

    # Bind mount the blog contents
    bindMounts = {
      "/blog-contents" = {
        hostPath = "${blogContents}";
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "molesk") // {
      imports = [
        inputs.molesk.nixosModules.default
      ];

      services.molesk = {
        enable = true;
        inherit (containerConfig.molesk) port;
        data = "/blog-contents";
        settings = {
          title = "Jesse Karjalainen";
          image = "/blog-contents/profile.jpg";
          links = [
            {
              fab = "fa-github";
              url = "https://github.com/tupakkatapa";
            }
            {
              fab = "fa-x-twitter";
              url = "https://x.com/tupakkatapa";
            }
            {
              fab = "fa-linkedin-in";
              url = "https://www.linkedin.com/in/jesse-karjalainen-a7bb612b8/";
            }
          ];
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.molesk.port ];
      };
    };
  };

  # Ensure host directories for potential writable state exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/molesk/appdata 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/molesk/appdata - ${uid} ${uid} -"
  ];
}
