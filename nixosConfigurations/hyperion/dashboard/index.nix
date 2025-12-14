{ pkgs, lib, config, domain, ... }:
let
  networkd = config.systemd.network;
  inherit (config.services) nixie;

  # Get all netdevs (bridges, wireguard, etc.)
  netdevs = lib.mapAttrsToList
    (_: cfg: {
      id = cfg.netdevConfig.Name;
      kind = cfg.netdevConfig.Kind;
      wireguardPeers = cfg.wireguardPeers or [ ];
    })
    networkd.netdevs;

  # Get all networks (interface configs), excluding wildcards
  networks = lib.filter (n: !(lib.hasInfix "*" n.id)) (
    lib.mapAttrsToList
      (name: cfg: {
        id = cfg.matchConfig.Name or name;
        inherit (cfg) address;
        bridge = cfg.networkConfig.Bridge or null;
        dhcp = cfg.networkConfig.DHCP or null;
      })
      (lib.filterAttrs (_: v: v.enable) networkd.networks)
  );

  # Helper to get IP from network config
  getNetworkIp = netId:
    let net = lib.findFirst (n: n.id == netId) null networks;
    in if net == null then ""
    else if net.address != [ ] then lib.head net.address
    else if net.dhcp != null && net.dhcp != "no" then "DHCP"
    else "";

  # Bridge members (interfaces assigned to bridges)
  bridgeMembers = lib.filter (n: n.bridge != null) networks;

  # Get interfaces for a bridge
  getBridgeInterfaces = bridgeId:
    map (m: m.id) (lib.filter (m: m.bridge == bridgeId) bridgeMembers);

  # Find which bridge a subnet uses
  findSubnetBridge = subnet:
    let
      iface = lib.head (subnet.interfaces or [ ]);
      net = lib.findFirst (n: n.id == iface) null networks;
    in
    if net != null then net.bridge else null;

  # Menu info for hosts (optional - may not exist)
  menuInfo = lib.listToAttrs (map
    (m: {
      inherit (m) name;
      value = m.hosts or [ ];
    })
    (nixie.file-server.menus or [ ]));

  # === NODES ===

  routerNode = {
    id = config.networking.hostName;
    type = "router";
    label = config.networking.hostName;
  };

  wanNode =
    let
      iface = nixie.dhcp.wan.interface;
    in
    [{
      id = iface;
      type = "external";
      label = "wan";
      interface = iface;
      ip = getNetworkIp iface;
    }];

  # Get default menu for a bridge
  getDefaultImages = bridgeId:
    let
      subnet = lib.findFirst (s: "br-${s.name}" == bridgeId) null nixie.dhcp.subnets;
    in
    if subnet != null && subnet.defaultMenu or null != null
    then menuInfo.${subnet.defaultMenu} or [ ]
    else [ ];

  networkNodes = map
    (nd: {
      inherit (nd) id;
      type = "network";
      label = nd.id;
      ip = getNetworkIp nd.id;
      interfaces = getBridgeInterfaces nd.id;
      defaultImages = getDefaultImages nd.id;
    })
    netdevs;

  # Declarative hosts from nixie config (with MAC for matching)
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
          bridge = findSubnetBridge subnet;
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
        nd.wireguardPeers
    )
    (lib.filter (nd: nd.kind == "wireguard") netdevs));

  allNodes = [ routerNode ] ++ wanNode ++ networkNodes ++ hostNodes ++ peerNodes;

  # === LINKS ===

  wanLinks = map (n: { source = n.id; target = routerNode.id; }) wanNode;
  networkLinks = map (n: { source = routerNode.id; target = n.id; }) networkNodes;
  hostLinks = lib.filter (l: l.target != null) (map (h: { source = h.id; target = h.bridge; }) hostNodes);
  peerLinks = map (p: { source = p.id; target = p.wgInterface; }) peerNodes;

  allLinks = wanLinks ++ networkLinks ++ hostLinks ++ peerLinks;

  # Filter internal attributes from JSON output
  filterInternal = n: lib.filterAttrs (k: _: !(lib.elem k [ "wgInterface" "bridge" ])) n;
  nodesJson = builtins.toJSON (map filterInternal allNodes);
  linksJson = builtins.toJSON allLinks;

  # Declarative hosts lookup (MAC -> node info) for frontend matching
  declarativeHostsJson = builtins.toJSON (lib.listToAttrs (map
    (h: { name = lib.toLower h.mac; value = { inherit (h) id label ip; }; })
    hostNodes));


  # Nginx listen addresses (all netdev IPs)
  listenAddrs = lib.filter (a: a != null) (map
    (nd:
      let net = lib.findFirst (n: n.id == nd.id) null networks;
      in if net != null && net.address != [ ]
      then lib.head (lib.splitString "/" (lib.head net.address))
      else null
    )
    netdevs);

  indexPage = pkgs.writeTextDir "index.html" ''
    <!DOCTYPE html>
    <html>
    <head>
      <title>${domain}</title>
      <meta charset="UTF-8">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body, html {
          font-family: 'IBM Plex Mono', monospace;
          background: #121212;
          background-image:
            linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
          background-size: 40px 40px;
          color: #fff;
          height: 100vh;
          overflow: hidden;
        }
        svg { display: block; }
        .link { stroke: #333; stroke-width: 1.5; }
        .node rect, .node circle, .node polygon { fill: #fff; }
        .node.online rect, .node.online circle, .node.online polygon { fill: #4ade80; }
        .node.offline rect, .node.offline circle, .node.offline polygon { fill: #f87171; }
        .node.dynamic rect { fill: #60a5fa; }
        .label { fill: #eee; font-size: 10px; text-anchor: middle; pointer-events: none; }
        .title { position: absolute; top: 20px; left: 50%; transform: translateX(-50%); font-size: 18px; color: #eee; }
        .legend { position: absolute; bottom: 20px; left: 20px; background: #1f1f1f; border: 1px solid #333; border-radius: 10px; padding: 16px 20px; font-size: 11px; color: #888; }
        .legend-title { color: #eee; font-size: 12px; margin-bottom: 12px; font-weight: bold; }
        .legend-item { display: flex; align-items: center; margin: 8px 0; }
        .legend-icon { width: 24px; height: 16px; display: flex; align-items: center; justify-content: center; margin-right: 10px; }
        .legend-diamond { width: 10px; height: 10px; background: #fff; transform: rotate(45deg); }
        .legend-circle { width: 14px; height: 14px; background: #fff; border-radius: 50%; }
        .legend-square { width: 12px; height: 12px; background: #fff; }
        .legend-line-online { width: 20px; height: 4px; background: #4ade80; border-radius: 2px; }
        .legend-line-offline { width: 20px; height: 4px; background: #f87171; border-radius: 2px; }
        .legend-line-dynamic { width: 20px; height: 4px; background: #60a5fa; border-radius: 2px; }
        .legend-triangle { width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-bottom: 12px solid #fff; }
        .tooltip { position: absolute; background: #1f1f1f; border: 1px solid #333; border-radius: 6px; padding: 10px 14px; font-size: 11px; color: #ccc; pointer-events: none; opacity: 0; transition: opacity 0.15s; max-width: 250px; }
        .tooltip-title { color: #fff; font-size: 13px; font-weight: bold; margin-bottom: 6px; }
        .tooltip-row { margin: 4px 0; color: #888; }
        .tooltip-row span { color: #ccc; }
        .status { position: absolute; top: 20px; right: 20px; font-size: 11px; color: #666; }
      </style>
    </head>
    <body>
      <div class="title">${domain}</div>
      <div class="status" id="status">Loading...</div>
      <div class="legend">
        <div class="legend-title">Legend</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-diamond"></div></div> Router</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-circle"></div></div> Network</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-square"></div></div> Host</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-triangle"></div></div> External</div>
        <div class="legend-title" style="margin-top: 12px;">Colors</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-dynamic"></div></div> Dynamic</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-online"></div></div> Online</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-offline"></div></div> Offline</div>
      </div>
      <svg id="network"></svg>
      <div class="tooltip" id="tooltip"></div>
      <script src="https://d3js.org/d3.v7.min.js"></script>
      <script>
        // Static nodes from Nix config
        const staticNodes = ${nodesJson};
        const staticLinks = ${linksJson};
        const declarativeHosts = ${declarativeHostsJson};

        // Track all nodes and links (will be updated dynamically)
        let nodes = [...staticNodes];
        let links = [...staticLinks];

        // Set initial positions by type to avoid tangled start
        const cx = window.innerWidth / 2, cy = window.innerHeight / 2;
        let netIdx = 0, hostIdx = 0, peerIdx = 0;
        nodes.forEach(n => {
          if (n.type === 'router') { n.x = cx; n.y = cy; }
          else if (n.type === 'external' && n.interface) { n.x = cx; n.y = cy - 120; } // WAN
          else if (n.type === 'network') { n.x = cx - 150 + netIdx * 150; n.y = cy + 100; netIdx++; }
          else if (n.type === 'host') { n.x = cx - 200 + hostIdx * 100; n.y = cy + 220; hostIdx++; }
          else if (n.type === 'external') { n.x = cx + 200 + peerIdx * 80; n.y = cy + 100; peerIdx++; } // WG peers
        });

        const svg = d3.select('#network')
          .attr('width', window.innerWidth)
          .attr('height', window.innerHeight);

        const linkGroup = svg.append('g');
        const nodeGroup = svg.append('g');
        const tooltip = d3.select('#tooltip');
        const status = d3.select('#status');

        const simulation = d3.forceSimulation(nodes)
          .force('link', d3.forceLink(links).id(d => d.id).distance(100))
          .force('charge', d3.forceManyBody().strength(-400))
          .force('center', d3.forceCenter(window.innerWidth / 2, window.innerHeight / 2))
          .force('collision', d3.forceCollide().radius(60));

        // Shape definitions by type
        const shapes = {
          router: g => g.append('rect').attr('width', 14).attr('height', 14).attr('x', -7).attr('y', -7).attr('transform', 'rotate(45)'),
          network: g => g.append('circle').attr('r', 7),
          host: g => g.append('rect').attr('width', 14).attr('height', 14).attr('x', -7).attr('y', -7),
          external: g => g.append('polygon').attr('points', '0,-8 7,6 -7,6')
        };

        const getNodeClass = d => {
          let cls = 'node';
          if (d.dynamic) cls += ' dynamic';
          else if (d.online === true) cls += ' online';
          else if (d.online === false) cls += ' offline';
          return cls;
        };

        function updateGraph() {
          // Update links
          const link = linkGroup.selectAll('line').data(links, d => (d.source.id || d.source) + '-' + (d.target.id || d.target));
          link.exit().remove();
          link.enter().append('line').attr('class', 'link');

          // Update nodes
          const node = nodeGroup.selectAll('g.node').data(nodes, d => d.id);

          node.exit().remove();

          const nodeEnter = node.enter().append('g')
            .attr('class', getNodeClass)
            .style('cursor', 'grab')
            .on('mouseenter', (e, d) => {
              let html = '<div class="tooltip-title">' + d.label + '</div>';
              if (d.interface) html += '<div class="tooltip-row">Interface: <span>' + d.interface + '</span></div>';
              if (d.interfaces?.length) html += '<div class="tooltip-row">Interfaces: <span>' + d.interfaces.join(', ') + '</span></div>';
              if (d.ip) html += '<div class="tooltip-row">IP: <span>' + d.ip + '</span></div>';
              if (d.mac) html += '<div class="tooltip-row">MAC: <span>' + d.mac + '</span></div>';
              if (d.images?.length) html += '<div class="tooltip-row">Images: <span>' + d.images.join(', ') + '</span></div>';
              if (d.defaultImages?.length) html += '<div class="tooltip-row">Default: <span>' + d.defaultImages.join(', ') + '</span></div>';
              tooltip.html(html).style('left', (e.pageX + 15) + 'px').style('top', (e.pageY - 10) + 'px').style('opacity', 1);
            })
            .on('mousemove', e => tooltip.style('left', (e.pageX + 15) + 'px').style('top', (e.pageY - 10) + 'px'))
            .on('mouseleave', () => tooltip.style('opacity', 0))
            .call(d3.drag()
              .on('start', e => { if (!e.active) simulation.alphaTarget(0.3).restart(); e.subject.fx = e.subject.x; e.subject.fy = e.subject.y; })
              .on('drag', e => { e.subject.fx = e.x; e.subject.fy = e.y; })
              .on('end', e => { if (!e.active) simulation.alphaTarget(0); e.subject.fx = null; e.subject.fy = null; }));

          // Draw shapes for new nodes
          Object.entries(shapes).forEach(([type, draw]) => draw(nodeEnter.filter(d => d.type === type)));
          nodeEnter.append('text').attr('class', 'label').attr('dy', 26).text(d => d.label);

          // Update classes for existing nodes (online/offline status)
          node.attr('class', getNodeClass);

          // Restart simulation with new data
          simulation.nodes(nodes);
          simulation.force('link').links(links);
          simulation.alpha(0.3).restart();
        }

        // Fetch dynamic host status
        async function fetchStatus() {
          try {
            const res = await fetch('/api/hosts.json?_=' + Date.now());
            if (!res.ok) throw new Error('Failed to fetch');
            const data = await res.json();

            // Index hosts by IP for efficient lookup
            const hostsByIp = {};
            data.hosts.forEach(h => { hostsByIp[h.ip] = h; });

            // Update online status for declarative hosts
            nodes.forEach(n => {
              if (n.type === 'host' && n.declarative) {
                const dynHost = hostsByIp[n.ip];
                n.online = dynHost ? dynHost.online : false;
              }
            });

            // Build set of current dynamic host IDs from API
            const currentDynamicIds = new Set();
            data.hosts.forEach(h => {
              const mac = h.mac.toLowerCase();
              if (!declarativeHosts[mac]) {
                currentDynamicIds.add('dyn-' + mac.replace(/:/g, ""));
              }
            });

            // Remove dynamic hosts that are no longer in leases
            for (let i = nodes.length - 1; i >= 0; i--) {
              if (nodes[i].dynamic && !currentDynamicIds.has(nodes[i].id)) {
                const id = nodes[i].id;
                nodes.splice(i, 1);
                // Remove associated links
                for (let j = links.length - 1; j >= 0; j--) {
                  const src = links[j].source.id || links[j].source;
                  if (src === id) links.splice(j, 1);
                }
              }
            }

            // Add/update dynamic hosts that aren't declarative
            const existingIds = new Set(nodes.map(n => n.id));
            data.hosts.forEach(h => {
              const mac = h.mac.toLowerCase();
              // Skip if this MAC belongs to a declarative host
              if (declarativeHosts[mac]) return;

              const id = 'dyn-' + mac.replace(/:/g, "");
              if (!existingIds.has(id)) {
                const newNode = {
                  id,
                  type: 'host',
                  label: h.hostname || h.ip,
                  ip: h.ip,
                  mac: h.mac,
                  online: h.online,
                  dynamic: true,
                  bridge: h.bridge
                };
                nodes.push(newNode);
                // Add link to bridge
                if (h.bridge) {
                  links.push({ source: id, target: h.bridge });
                }
              } else {
                // Update existing dynamic node
                const existing = nodes.find(n => n.id === id);
                if (existing) {
                  existing.online = h.online;
                  existing.label = h.hostname || h.ip;
                }
              }
            });

            status.text('Updated: ' + new Date().toLocaleTimeString());
            updateGraph();
          } catch (err) {
            status.text('Status: error fetching');
            console.error(err);
          }
        }

        // Initial render
        updateGraph();

        simulation.on('tick', () => {
          linkGroup.selectAll('line')
            .attr('x1', d => d.source.x).attr('y1', d => d.source.y)
            .attr('x2', d => d.target.x).attr('y2', d => d.target.y);
          nodeGroup.selectAll('g.node')
            .attr('transform', d => 'translate(' + d.x + ',' + d.y + ')');
        });

        window.addEventListener('resize', () => {
          svg.attr('width', window.innerWidth).attr('height', window.innerHeight);
          simulation.force('center', d3.forceCenter(window.innerWidth / 2, window.innerHeight / 2)).alpha(0.3).restart();
        });

        // Fetch status every 30 seconds
        fetchStatus();
        setInterval(fetchStatus, 30000);
      </script>
    </body>
    </html>
  '';
in
{
  services.nginx.virtualHosts."${domain}" = {
    default = true;
    root = indexPage;
    listen = map (addr: { inherit addr; port = 80; }) listenAddrs;
    locations."/api/hosts.json" = {
      alias = "/var/lib/network-status/hosts.json";
      extraConfig = ''
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Access-Control-Allow-Origin "*";
      '';
    };
  };
}
