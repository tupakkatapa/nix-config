{ pkgs, lib, config, domain, ... }:
let
  networkd = config.systemd.network;
  inherit (config.services) nixie;

  # Self-signed certificate for internal dashboard
  selfSignedCert = pkgs.runCommand "self-signed-cert"
    {
      buildInputs = [ pkgs.openssl ];
    } ''
    mkdir -p $out
    openssl req -x509 -newkey rsa:4096 -keyout $out/key.pem -out $out/cert.pem -days 3650 -nodes \
      -subj "/CN=${domain}" \
      -addext "subjectAltName = DNS:${domain}, IP:10.42.0.1"
  '';

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

  # Collect router's IPs on each bridge
  routerIps = lib.filter (x: x != null) (map
    (nd:
      let net = lib.findFirst (n: n.id == nd.id) null networks;
      in if net != null && net.address != [ ]
      then { bridge = nd.id; ip = lib.head (lib.splitString "/" (lib.head net.address)); }
      else null
    )
    (lib.filter (nd: nd.kind == "bridge") netdevs));

  routerNode = {
    id = config.networking.hostName;
    type = "router";
    label = config.networking.hostName;
    ips = routerIps;
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
          color: #fff;
          height: 100vh;
          overflow: hidden;
        }
        svg { display: block; }
        .link { stroke: #333; stroke-width: 1.5; }
        .node rect, .node circle, .node polygon { fill: #fff; }
        .node.reachable rect, .node.reachable circle, .node.reachable polygon { fill: #22c55e; }
        .node.stale rect, .node.stale circle, .node.stale polygon { fill: #eab308; }
        .node.failed rect, .node.failed circle, .node.failed polygon { fill: #ef4444; }
        .label { fill: #eee; font-size: 10px; text-anchor: middle; pointer-events: none; }
        .title { position: absolute; top: 20px; left: 50%; transform: translateX(-50%); font-size: 18px; color: #eee; }
        .legend { position: absolute; bottom: 20px; left: 20px; background: #1f1f1f; border: 1px solid #333; border-radius: 10px; padding: 16px 20px; font-size: 11px; color: #888; }
        .legend-title { color: #eee; font-size: 12px; margin-bottom: 12px; font-weight: bold; }
        .legend-item { display: flex; align-items: center; margin: 8px 0; }
        .legend-icon { width: 24px; height: 16px; display: flex; align-items: center; justify-content: center; margin-right: 10px; }
        .legend-diamond { width: 10px; height: 10px; background: #fff; transform: rotate(45deg); }
        .legend-circle { width: 14px; height: 14px; background: #fff; border-radius: 50%; }
        .legend-square { width: 12px; height: 12px; background: #fff; }
        .legend-line-reachable { width: 20px; height: 4px; background: #22c55e; border-radius: 2px; }
        .legend-line-stale { width: 20px; height: 4px; background: #eab308; border-radius: 2px; }
        .legend-line-failed { width: 20px; height: 4px; background: #ef4444; border-radius: 2px; }
        .legend-line-declarative { width: 20px; height: 4px; background: #fff; border-radius: 2px; }
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
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-declarative"></div></div> Declarative</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-reachable"></div></div> Reachable</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-stale"></div></div> Stale</div>
        <div class="legend-item"><div class="legend-icon"><div class="legend-line-failed"></div></div> Failed</div>
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

        // Grid pattern
        const defs = svg.append('defs');
        defs.append('pattern')
          .attr('id', 'grid')
          .attr('width', 40)
          .attr('height', 40)
          .attr('patternUnits', 'userSpaceOnUse')
          .append('path')
          .attr('d', 'M 40 0 L 0 0 0 40')
          .attr('fill', 'none')
          .attr('stroke', 'rgba(255,255,255,0.03)')
          .attr('stroke-width', 1);

        // Diagonal pattern for declarative nodes
        const diagPattern = defs.append('pattern')
          .attr('id', 'diag')
          .attr('width', 6)
          .attr('height', 6)
          .attr('patternUnits', 'userSpaceOnUse')
          .attr('patternTransform', 'rotate(45)');
        diagPattern.append('rect').attr('width', 6).attr('height', 6).attr('fill', 'currentColor');
        diagPattern.append('line').attr('x1', 0).attr('y1', 0).attr('x2', 0).attr('y2', 6).attr('stroke', 'rgba(255,255,255,0.4)').attr('stroke-width', 2);

        // Container for zoom/pan
        const container = svg.append('g');
        container.append('rect')
          .attr('width', 10000)
          .attr('height', 10000)
          .attr('x', -5000)
          .attr('y', -5000)
          .attr('fill', 'url(#grid)');
        const linkGroup = container.append('g');
        const nodeGroup = container.append('g');

        // Zoom behavior
        const zoom = d3.zoom()
          .scaleExtent([0.3, 4])
          .on('zoom', e => container.attr('transform', e.transform));
        svg.call(zoom);
        const tooltip = d3.select('#tooltip');
        const status = d3.select('#status');

        const simulation = d3.forceSimulation(nodes)
          .force('link', d3.forceLink(links).id(d => d.id).distance(100))
          .force('charge', d3.forceManyBody().strength(-400))
          .force('center', d3.forceCenter(window.innerWidth / 2, window.innerHeight / 2))
          .force('collision', d3.forceCollide().radius(60));

        // Shape definitions by type
        const shapes = {
          router: g => g.append('rect').attr('width', 18).attr('height', 18).attr('x', -9).attr('y', -9).attr('transform', 'rotate(45)'),
          network: g => g.append('circle').attr('r', 9),
          host: g => g.append('rect').attr('width', 18).attr('height', 18).attr('x', -9).attr('y', -9),
          external: g => g.append('polygon').attr('points', '0,-10 9,8 -9,8')
        };

        const getNodeClass = d => {
          let cls = 'node';
          // State colors apply to all hosts
          if (d.state === 'reachable') cls += ' reachable';
          else if (d.state === 'stale') cls += ' stale';
          else if (d.state === 'failed') cls += ' failed';
          // Declarative hosts get white border
          if (d.declarative) cls += ' declarative';
          return cls;
        };

        function updateGraph(restartSimulation = true) {
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
              if (d.ips?.length) d.ips.forEach(x => { html += '<div class="tooltip-row">' + x.bridge + ': <span>' + x.ip + '</span></div>'; });
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

          // Add pattern overlay for declarative nodes
          nodeEnter.filter(d => d.declarative).each(function(d) {
            const g = d3.select(this);
            let overlay;
            if (d.type === 'host') {
              overlay = g.append('rect').attr('width', 18).attr('height', 18).attr('x', -9).attr('y', -9);
            } else if (d.type === 'router') {
              overlay = g.append('rect').attr('width', 18).attr('height', 18).attr('x', -9).attr('y', -9).attr('transform', 'rotate(45)');
            } else if (d.type === 'network') {
              overlay = g.append('circle').attr('r', 9);
            } else if (d.type === 'external') {
              overlay = g.append('polygon').attr('points', '0,-10 9,8 -9,8');
            }
            if (overlay) overlay.attr('fill', 'url(#diag)').attr('opacity', 0.3);
          });

          nodeEnter.append('text').attr('class', 'label').attr('dy', 26).text(d => d.label);

          // Update classes for existing nodes (state changes)
          node.attr('class', getNodeClass);

          // Only restart simulation when topology changes (nodes added/removed)
          if (restartSimulation) {
            simulation.nodes(nodes);
            simulation.force('link').links(links);
            simulation.alpha(0.3).restart();
          }
        }

        // Fetch WAN IP
        async function fetchWanIp() {
          try {
            const res = await fetch('/api/wan.json?_=' + Date.now());
            if (!res.ok) return;
            const data = await res.json();
            // ip -j addr returns array with addr_info containing local IP
            const addr = data[0]?.addr_info?.[0]?.local;
            if (addr) {
              const wanNode = nodes.find(n => n.interface);
              if (wanNode) wanNode.ip = addr;
            }
          } catch (err) { console.error('WAN fetch error:', err); }
        }

        // Fetch dynamic host status
        async function fetchStatus() {
          try {
            const res = await fetch('/api/hosts.json?_=' + Date.now());
            if (!res.ok) throw new Error('Failed to fetch');
            const raw = await res.json();

            // Transform raw ip neigh output and filter to bridge interfaces, IPv4 only
            // States: REACHABLE (green), STALE/DELAY/PROBE (yellow), FAILED/INCOMPLETE/missing (red)
            const getState = s => {
              if (!s) return 'failed';
              if (s.includes('REACHABLE')) return 'reachable';
              if (s.includes('STALE') || s.includes('DELAY') || s.includes('PROBE')) return 'stale';
              return 'failed';
            };
            const hosts = raw
              .filter(h => h.dev && h.dev.startsWith('br-') && h.dst && !h.dst.includes(':'))
              .map(h => ({
                ip: h.dst,
                mac: h.lladdr,
                state: getState(h.state),
                bridge: h.dev
              }));

            // Index hosts by IP for efficient lookup
            const hostsByIp = {};
            hosts.forEach(h => { hostsByIp[h.ip] = h; });

            // Track if topology changed (nodes added/removed)
            let topologyChanged = false;

            // Update state for declarative hosts
            nodes.forEach(n => {
              if (n.type === 'host' && n.declarative) {
                const dynHost = hostsByIp[n.ip];
                n.state = dynHost ? dynHost.state : 'failed';
              }
            });

            // Build set of current dynamic host IDs from API
            const currentDynamicIds = new Set();
            hosts.forEach(h => {
              if (!h.mac) return;
              const mac = h.mac.toLowerCase();
              if (!declarativeHosts[mac]) {
                currentDynamicIds.add('dyn-' + mac.replace(/:/g, ""));
              }
            });

            // Remove dynamic hosts that are no longer in ARP table
            for (let i = nodes.length - 1; i >= 0; i--) {
              if (nodes[i].dynamic && !currentDynamicIds.has(nodes[i].id)) {
                const id = nodes[i].id;
                nodes.splice(i, 1);
                topologyChanged = true;
                // Remove associated links
                for (let j = links.length - 1; j >= 0; j--) {
                  const src = links[j].source.id || links[j].source;
                  if (src === id) links.splice(j, 1);
                }
              }
            }

            // Add/update dynamic hosts that aren't declarative
            const existingIds = new Set(nodes.map(n => n.id));
            hosts.forEach(h => {
              if (!h.mac) return;
              const mac = h.mac.toLowerCase();
              // Skip if this MAC belongs to a declarative host
              if (declarativeHosts[mac]) return;

              const id = 'dyn-' + mac.replace(/:/g, "");
              if (!existingIds.has(id)) {
                const newNode = {
                  id,
                  type: 'host',
                  label: h.ip,
                  ip: h.ip,
                  mac: h.mac,
                  state: h.state,
                  dynamic: true,
                  bridge: h.bridge
                };
                nodes.push(newNode);
                topologyChanged = true;
                // Add link to bridge
                if (h.bridge) {
                  links.push({ source: id, target: h.bridge });
                }
              } else {
                // Update existing dynamic node
                const existing = nodes.find(n => n.id === id);
                if (existing) {
                  existing.state = h.state;
                }
              }
            });

            status.text('Updated: ' + new Date().toLocaleTimeString());
            updateGraph(topologyChanged);
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
        });

        // Fetch on load, then poll while tab is visible
        let statusInterval, wanInterval;

        function startPolling() {
          fetchStatus();
          fetchWanIp();
          statusInterval = setInterval(fetchStatus, 5000);
          wanInterval = setInterval(fetchWanIp, 30000);
        }

        function stopPolling() {
          clearInterval(statusInterval);
          clearInterval(wanInterval);
        }

        document.addEventListener('visibilitychange', () => {
          if (document.hidden) stopPolling();
          else startPolling();
        });

        startPolling();
      </script>
    </body>
    </html>
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
