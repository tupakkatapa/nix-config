{ lib
, config
, domain
, dataDir
, servicesConfig
, ...
}:
let
  containerSubnet = "10.233.1";
  containerNetwork = {
    hostAddress = "${containerSubnet}.1";
    kavita = {
      address = "${containerSubnet}.10";
    };
  };
in
{
  # Containers
  imports = [
    (import ./kavita.nix { inherit config lib domain dataDir servicesConfig containerNetwork; })
  ];
  boot.enableContainers = true;

  # Host networking for all containers
  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp0s31f6";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };
    firewall = {
      extraCommands = ''
        iptables -t nat -A PREROUTING -p tcp -d 192.168.1.8 --dport ${toString servicesConfig.kavita.port} -j DNAT --to-destination ${containerNetwork.kavita.address}:${toString servicesConfig.kavita.port}
        iptables -A FORWARD -p tcp -d ${containerNetwork.kavita.address} --dport ${toString servicesConfig.kavita.port} -j ACCEPT
      '';
    };
  };
}
