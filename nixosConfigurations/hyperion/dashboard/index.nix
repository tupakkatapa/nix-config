{ pkgs, lib, config, domain, ... }:
let
  networkd = config.systemd.network;
  inherit (config.services) nixie;
  hostname = config.networking.hostName;

  # Self-signed certificate for internal dashboard
  selfSignedCert = pkgs.runCommand "self-signed-cert" { buildInputs = [ pkgs.openssl ]; } ''
    mkdir -p $out
    openssl req -x509 -newkey rsa:4096 -keyout $out/key.pem -out $out/cert.pem \
      -days 3650 -nodes -subj "/CN=${domain}" \
      -addext "subjectAltName = DNS:${domain}, IP:10.42.0.1"
  '';

  # === DATA DEFINITIONS ===

  # Ordered lists for logical legend display
  nodeTypes = [
    { name = "router"; label = "Router"; shape = "diamond"; }
    { name = "network"; label = "Network"; shape = "circle"; }
    { name = "host"; label = "Host"; shape = "square"; }
    { name = "external"; label = "External"; shape = "triangle"; }
  ];

  states = [
    { name = "declarative"; label = "Declarative"; color = "#ffffff"; }
    { name = "reachable"; label = "Reachable"; color = "#22c55e"; }
    { name = "stale"; label = "Stale"; color = "#eab308"; }
    { name = "failed"; label = "Failed"; color = "#ef4444"; }
  ];

  # Convert to attrsets for JSON export
  nodeTypesAttrs = lib.listToAttrs (map (t: { inherit (t) name; value = { inherit (t) shape; }; }) nodeTypes);

  # === EXTRACT NETWORK DATA ===

  netdevs = lib.mapAttrsToList
    (_: cfg: {
      id = cfg.netdevConfig.Name;
      kind = cfg.netdevConfig.Kind;
      peers = cfg.wireguardPeers or [ ];
    })
    networkd.netdevs;

  networks = lib.pipe networkd.networks [
    (lib.filterAttrs (_: v: v.enable))
    (lib.mapAttrsToList (name: cfg: {
      id = cfg.matchConfig.Name or name;
      inherit (cfg) address;
      bridge = cfg.networkConfig.Bridge or null;
    }))
    (lib.filter (n: !(lib.hasInfix "*" n.id)))
  ];

  # Helper to find network by ID
  getNet = id: lib.findFirst (n: n.id == id) null networks;
  getIp = id:
    let net = getNet id; in
    if net != null && net.address != [ ] then lib.head net.address else "";

  # Filter netdevs by kind
  bridges = lib.filter (nd: nd.kind == "bridge") netdevs;
  wgDevs = lib.filter (nd: nd.kind == "wireguard") netdevs;

  menuInfo = lib.listToAttrs (map (m: { inherit (m) name; value = m.hosts or [ ]; })
    (nixie.file-server.menus or [ ]));

  # === BUILD NODES ===

  routerNode = {
    id = hostname;
    type = "router";
    label = hostname;
    ips = lib.pipe bridges [
      (map (nd:
        let net = getNet nd.id; in
        if net != null && net.address != [ ]
        then { bridge = nd.id; ip = lib.head (lib.splitString "/" (lib.head net.address)); }
        else null))
      (lib.filter (x: x != null))
    ];
  };

  wanNode = let iface = nixie.dhcp.wan.interface; in {
    id = iface;
    type = "external";
    label = "wan";
    interface = iface;
    ip = getIp iface;
  };

  networkNodes = map
    (nd: {
      inherit (nd) id;
      type = "network";
      label = nd.id;
      ip = getIp nd.id;
      interfaces = map (m: m.id) (lib.filter (n: n.bridge == nd.id) networks);
      defaultImages =
        let
          subnet = lib.findFirst (s: "br-${s.name}" == nd.id) null nixie.dhcp.subnets;
        in
        if subnet != null then menuInfo.${subnet.defaultMenu or ""} or [ ] else [ ];
    })
    bridges;

  hostNodes = lib.flatten (map
    (subnet:
      map
        (client: {
          id = client.menu;
          type = "host";
          label = client.menu;
          ip = client.address;
          inherit (client) mac;
          images = menuInfo.${client.menu} or [ ];
          bridge =
            let
              iface = lib.head (subnet.interfaces or [ ]);
              net = getNet iface;
            in
            if net != null then net.bridge else null;
          declarative = true;
        })
        (subnet.clients or [ ])
    )
    nixie.dhcp.subnets);

  peerNodes = lib.flatten (map
    (nd:
      lib.imap0
        (i: peer: {
          id = "${nd.id}-peer-${toString i}";
          type = "external";
          label = lib.head (lib.splitString "/" (lib.head peer.AllowedIPs));
          wgInterface = nd.id;
        })
        nd.peers
    )
    wgDevs);

  allNodes = [ routerNode wanNode ] ++ networkNodes ++ hostNodes ++ peerNodes;

  # === BUILD LINKS ===

  allLinks =
    [{ source = wanNode.id; target = routerNode.id; }] ++
    map (n: { source = routerNode.id; target = n.id; }) networkNodes ++
    lib.filter (l: l.target != null) (map (h: { source = h.id; target = h.bridge; }) hostNodes) ++
    map (p: { source = p.id; target = routerNode.id; }) peerNodes;

  # === SUBSTITUTION VALUES ===

  filterInternal = n: lib.filterAttrs (k: _: !(lib.elem k [ "wgInterface" "bridge" ])) n;

  substitutions = {
    inherit domain;
    nodesJson = builtins.toJSON (map filterInternal allNodes);
    linksJson = builtins.toJSON allLinks;
    declarativeHostsJson = builtins.toJSON (lib.listToAttrs
      (map (h: { name = lib.toLower h.mac; value = { inherit (h) id label ip; }; }) hostNodes));
    nodeTypesJson = builtins.toJSON nodeTypesAttrs;
    statesCss = lib.concatStringsSep "\n    " (map
      (s:
        ".node.${s.name} rect, .node.${s.name} circle, .node.${s.name} polygon { fill: ${s.color}; }"
      )
      states);
    legendColorsCss = lib.concatStringsSep "\n    " (map
      (s:
        ".legend-${s.name} { width: 20px; height: 4px; background: ${s.color}; border-radius: 2px; }"
      )
      states);
    shapeLegend = lib.concatStringsSep "\n    " (map
      (t:
        ''<div class="legend-item"><div class="legend-icon"><div class="legend-${t.shape}"></div></div>${t.label}</div>''
      )
      nodeTypes);
    colorLegend = lib.concatStringsSep "\n    " (map
      (s:
        ''<div class="legend-item"><div class="legend-icon"><div class="legend-${s.name}"></div></div>${s.label}</div>''
      )
      states);
  };

  # === D3.JS LOCAL COPY ===

  d3js = pkgs.fetchurl {
    url = "https://d3js.org/d3.v7.min.js";
    sha256 = "sha256-8glLv2FBs1lyLE/kVOtsSw8OQswQzHr5IfwVj864ZTk=";
  };

  # === BUILD DASHBOARD ===

  indexPage = pkgs.runCommand "dashboard" substitutions ''
    mkdir -p $out
    cp ${d3js} $out/d3.min.js
    substitute ${./index.html} $out/index.html \
      --subst-var domain \
      --subst-var shapeLegend \
      --subst-var colorLegend
    substitute ${./styles.css} $out/styles.css \
      --subst-var statesCss \
      --subst-var legendColorsCss
    substitute ${./app.js} $out/app.js \
      --subst-var nodesJson \
      --subst-var linksJson \
      --subst-var declarativeHostsJson \
      --subst-var nodeTypesJson
  '';
in
{
  services.nginx.virtualHosts."${domain}" = {
    default = true;
    root = indexPage;
    listen = [
      { addr = "10.42.0.1"; port = 80; ssl = false; }
      { addr = "10.42.0.1"; port = 443; ssl = true; }
    ];
    forceSSL = true;
    sslCertificate = "${selfSignedCert}/cert.pem";
    sslCertificateKey = "${selfSignedCert}/key.pem";
  };
}
