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
  uid = builtins.toString containerConfig.coditon-md.uid;
in
{
  containers.coditon-md = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.coditon-md) hostAddress localAddress;

    # Bind mount the blog contents
    bindMounts = {
      "/blog-contents" = {
        hostPath = "${blogContents}";
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "coditon-md") // {
      imports = [
        inputs.coditon-md.nixosModules.default
      ];

      services.coditon-md = {
        enable = true;
        inherit (containerConfig.coditon-md) port;
        dataDir = "/blog-contents";
        name = "Jesse Karjalainen";
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

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.coditon-md.port ];
      };
    };
  };

  # Ensure host directories for potential writable state exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/coditon-md/appdata 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/coditon-md/appdata - ${uid} ${uid} -"
  ];
}
