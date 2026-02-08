const CONFIG = {
  nodes: @nodesJson@,
  links: @linksJson@,
  declHosts: @declarativeHostsJson@,
  types: @nodeTypesJson@
};

const nodes = [...CONFIG.nodes], links = [...CONFIG.links];
const svg = d3.select('#network').attr('width', innerWidth).attr('height', innerHeight);
const infobox = d3.select('#infobox'), status = d3.select('#status'), toast = d3.select('#toast'), indicator = d3.select('#indicator');
const searchInput = document.getElementById('search');
const el = id => document.getElementById(id);

// === Formatting ===

function fmtUptime(seconds) {
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (d > 0) return d + 'd ' + h + 'h';
  if (h > 0) return h + 'h ' + m + 'm';
  return m + 'm';
}

function fmtBytes(bytes) {
  if (bytes >= 1e12) return (bytes / 1e12).toFixed(1) + ' TB';
  if (bytes >= 1e9) return (bytes / 1e9).toFixed(1) + ' GB';
  if (bytes >= 1e6) return (bytes / 1e6).toFixed(1) + ' MB';
  if (bytes >= 1e3) return (bytes / 1e3).toFixed(0) + ' KB';
  return bytes + ' B';
}

function getCounts() {
  const nets = nodes.filter(n => n.type === 'network').length;
  const hosts = nodes.filter(n => n.type === 'host').length;
  const peers = nodes.filter(n => n.type === 'external' && !n.interface).length;
  return nets + ' net \u00b7 ' + hosts + ' hosts \u00b7 ' + peers + ' peers';
}

function showToast(msg) {
  toast.text(msg).classed('show', true);
  setTimeout(() => toast.classed('show', false), 2000);
}

function copyValue(value) {
  navigator.clipboard.writeText(value).then(() => showToast('Copied: ' + value));
}

function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// === Infobox ===

let currentNode = null;
let hideTimeout = null;

function getScreenPos(d) {
  const transform = d3.zoomTransform(svg.node());
  return [transform.applyX(d.x), transform.applyY(d.y)];
}

function updateInfo(d) {
  currentNode = d;
  if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }

  const stateLabels = { declarative: 'Declarative', reachable: 'Reachable', stale: 'Stale', failed: 'Failed' };
  const rows = [
    { label: 'Type', value: d.type.charAt(0).toUpperCase() + d.type.slice(1) },
    d.state && { label: 'Status', value: stateLabels[d.state] || d.state },
    d.ip && { label: 'IP', value: d.ip },
    d.mac && { label: 'MAC', value: d.mac },
    d.interface && { label: 'Interface', value: d.interface },
    d.interfaces && d.interfaces.length && { label: 'Interfaces', value: d.interfaces.join(', ') },
    d.endpoint && { label: 'Endpoint', value: d.endpoint },
    d.images && d.images.length && { label: 'Images', value: d.images.join(', ') },
    d.dynamic && { label: 'Source', value: 'Dynamic' }
  ].filter(Boolean);

  const [sx, sy] = getScreenPos(d);
  infobox.html(
    '<div class="infobox-title">' + esc(d.label) + '</div>' +
    rows.map(r => '<div class="infobox-row"><span>' + esc(r.label) + '</span><span class="infobox-value" data-copy="' + esc(r.value) + '">' + esc(r.value) + '</span></div>').join('')
  );

  // Keep infobox within viewport
  const boxW = 220, boxH = rows.length * 25 + 40;
  let left = sx + 30, top = sy - 20;
  if (left + boxW > innerWidth - 20) left = sx - boxW - 30;
  if (top + boxH > innerHeight - 20) top = innerHeight - boxH - 20;
  if (top < 20) top = 20;
  infobox.style('left', left + 'px').style('top', top + 'px').classed('show', true);
}

function updateInfoPosition() {
  if (currentNode) {
    const [sx, sy] = getScreenPos(currentNode);
    const boxW = 220;
    let left = sx + 30, top = sy - 20;
    if (left + boxW > innerWidth - 20) left = sx - boxW - 30;
    if (top < 20) top = 20;
    infobox.style('left', left + 'px').style('top', top + 'px');
  }
}

function scheduleHide() {
  hideTimeout = setTimeout(() => {
    infobox.classed('show', false);
    currentNode = null;
  }, 100);
}

function cancelHide() {
  if (hideTimeout) { clearTimeout(hideTimeout); hideTimeout = null; }
}

const infoboxEl = document.getElementById('infobox');
infoboxEl.addEventListener('mouseenter', cancelHide);
infoboxEl.addEventListener('mouseleave', scheduleHide);
infoboxEl.addEventListener('click', e => {
  const val = e.target.closest('.infobox-value');
  if (val && val.dataset.copy) copyValue(val.dataset.copy);
});

// === SVG Setup ===

const defs = svg.append('defs');
defs.append('pattern').attr('id', 'grid').attr('width', 40).attr('height', 40).attr('patternUnits', 'userSpaceOnUse')
  .append('circle').attr('cx', 20).attr('cy', 20).attr('r', 0.5).attr('fill', 'rgba(255,255,255,0.06)');

// Glow filters per state
const glowColors = { declarative: '#ffffff', reachable: '#22c55e', stale: '#eab308', failed: '#ef4444' };
Object.entries(glowColors).forEach(([state, color]) => {
  const filter = defs.append('filter').attr('id', 'glow-' + state).attr('x', '-50%').attr('y', '-50%').attr('width', '200%').attr('height', '200%');
  filter.append('feGaussianBlur').attr('in', 'SourceGraphic').attr('stdDeviation', '3').attr('result', 'blur');
  filter.append('feFlood').attr('flood-color', color).attr('flood-opacity', '0.3').attr('result', 'color');
  filter.append('feComposite').attr('in', 'color').attr('in2', 'blur').attr('operator', 'in').attr('result', 'glow');
  const merge = filter.append('feMerge');
  merge.append('feMergeNode').attr('in', 'glow');
  merge.append('feMergeNode').attr('in', 'SourceGraphic');
});

const container = svg.append('g');
container.append('rect').attr('width', 10000).attr('height', 10000).attr('x', -5000).attr('y', -5000).attr('fill', 'url(#grid)');
const linkG = container.append('g'), linkOverlayG = container.append('g'), nodeG = container.append('g');

const zoom = d3.zoom().scaleExtent([0.3, 4]).on('zoom', e => {
  container.attr('transform', e.transform);
  updateInfoPosition();
});
svg.call(zoom);

function centerView() {
  const bounds = nodeG.node().getBBox();
  const fullWidth = innerWidth, fullHeight = innerHeight;
  const width = bounds.width, height = bounds.height;
  const midX = bounds.x + width / 2, midY = bounds.y + height / 2;
  const scale = Math.min(0.8 * fullWidth / width, 0.8 * fullHeight / height, 2);
  const translate = [fullWidth / 2 - scale * midX, fullHeight / 2 - scale * midY];
  svg.transition().duration(500).call(zoom.transform, d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale));
}

// === Force Simulation ===

const cx = innerWidth / 2, cy = innerHeight / 2;
let ni = 0, hi = 0, pi = 0;
nodes.forEach(n => {
  if (n.type === 'router') { n.x = cx; n.y = cy; }
  else if (n.type === 'external' && n.interface) { n.x = cx; n.y = cy - 120; }
  else if (n.type === 'network') { n.x = cx - 150 + ni++ * 150; n.y = cy + 100; }
  else if (n.type === 'host') { n.x = cx - 200 + hi++ * 100; n.y = cy + 220; }
  else if (n.type === 'external') { n.x = cx + 200 + pi++ * 80; n.y = cy + 100; }
});

const sim = d3.forceSimulation(nodes)
  .force('link', d3.forceLink(links).id(d => d.id).distance(100))
  .force('charge', d3.forceManyBody().strength(-400))
  .force('center', d3.forceCenter(cx, cy))
  .force('collision', d3.forceCollide().radius(60));

const drawShape = {
  diamond: g => g.append('rect').attr('width', 20).attr('height', 20).attr('x', -10).attr('y', -10).attr('rx', 2).attr('transform', 'rotate(45)'),
  circle: g => g.append('circle').attr('r', 11),
  square: g => g.append('rect').attr('width', 20).attr('height', 20).attr('x', -10).attr('y', -10).attr('rx', 3),
  triangle: g => g.append('polygon').attr('points', '0,-12 10,8 -10,8')
};

const getClass = d => ['node', d.state, d.declarative && 'declarative'].filter(Boolean).join(' ');
const getFilter = d => d.state && glowColors[d.state] ? 'url(#glow-' + d.state + ')' : null;

function render(restart = true) {
  linkG.selectAll('line').data(links, d => (d.source.id || d.source) + '-' + (d.target.id || d.target))
    .join('line').attr('class', 'link');
  linkOverlayG.selectAll('line').data(links, d => (d.source.id || d.source) + '-' + (d.target.id || d.target))
    .join('line').attr('class', 'link-overlay');

  const node = nodeG.selectAll('g.node').data(nodes, d => d.id);
  node.exit().remove();
  node.attr('class', getClass).attr('filter', getFilter);

  const enter = node.enter().append('g').attr('class', getClass).attr('filter', getFilter).style('cursor', 'grab')
    .on('mouseenter', (e, d) => updateInfo(d))
    .on('mouseleave', scheduleHide)
    .call(d3.drag()
      .on('start', e => { if (!e.active) sim.alphaTarget(0.3).restart(); e.subject.fx = e.subject.x; e.subject.fy = e.subject.y; })
      .on('drag', e => { e.subject.fx = e.x; e.subject.fy = e.y; })
      .on('end', e => { if (!e.active) sim.alphaTarget(0); e.subject.fx = e.subject.fy = null; }));

  enter.each(function(d) {
    const shape = CONFIG.types[d.type] && CONFIG.types[d.type].shape;
    if (shape && drawShape[shape]) drawShape[shape](d3.select(this));
  });
  enter.append('text').attr('class', 'label').attr('dy', 28).text(d => d.label);

  if (restart) { sim.nodes(nodes); sim.force('link').links(links); sim.alpha(0.3).restart(); }
  applySearch();
}

sim.on('tick', () => {
  linkG.selectAll('line').attr('x1', d => d.source.x).attr('y1', d => d.source.y).attr('x2', d => d.target.x).attr('y2', d => d.target.y);
  linkOverlayG.selectAll('line').attr('x1', d => d.source.x).attr('y1', d => d.source.y).attr('x2', d => d.target.x).attr('y2', d => d.target.y);
  nodeG.selectAll('g.node').attr('transform', d => 'translate(' + d.x + ',' + d.y + ')');
  updateInfoPosition();
});

// === State Change Tracking ===

const prevStates = {};
let firstPoll = true;

function checkStateChanges() {
  nodes.forEach(n => {
    if (!n.declarative && !(n.type === 'external' && !n.interface)) return;
    const prev = prevStates[n.id];
    if (!firstPoll && prev && prev !== n.state) {
      if (n.state === 'reachable') showToast(n.label + ' online');
      else if (n.state === 'failed') showToast(n.label + ' offline');
      else if (n.state === 'stale') showToast(n.label + ' stale');
    }
    prevStates[n.id] = n.state;
  });
  firstPoll = false;
}

// === Network Polling ===

const getState = s => !s ? 'failed' : s.includes('REACHABLE') ? 'reachable' : /STALE|DELAY|PROBE/.test(s) ? 'stale' : 'failed';

async function poll() {
  try {
    const [hostsRes, wanRes, wgRes] = await Promise.all([
      fetch('/api/hosts.json?_=' + Date.now()),
      fetch('/api/wan.json?_=' + Date.now()),
      fetch('/api/wg.json?_=' + Date.now())
    ]);

    if (wanRes.ok) {
      const wan = await wanRes.json();
      const wanNode = nodes.find(n => n.interface);
      if (wanNode && wan[0] && wan[0].addr_info && wan[0].addr_info[0]) wanNode.ip = wan[0].addr_info[0].local;
    }

    if (wgRes.ok) {
      const wgData = await wgRes.json();
      const wgPeers = wgData.flatMap(d => d.peers || []);
      const now = Math.floor(Date.now() / 1000);
      nodes.filter(n => n.type === 'external' && !n.interface).forEach(n => {
        const peer = wgPeers.find(p => p.allowed_ips && p.allowed_ips.some(ip => ip.startsWith(n.label)));
        if (peer) {
          const age = now - peer.latest_handshake;
          n.state = peer.latest_handshake === 0 ? 'failed' : age < 180 ? 'reachable' : 'stale';
          n.endpoint = peer.endpoint;
        }
      });
    }

    if (!hostsRes.ok) throw new Error('hosts fetch failed');
    const raw = await hostsRes.json();
    const hosts = raw.filter(h => h.dev && h.dev.startsWith('br-') && h.dst && !h.dst.includes(':'))
      .map(h => ({ ip: h.dst, mac: h.lladdr, state: getState(h.state), bridge: h.dev }));
    const byIp = {};
    hosts.forEach(h => { byIp[h.ip] = h; });

    let changed = false;

    nodes.filter(n => n.declarative).forEach(n => { n.state = byIp[n.ip] ? byIp[n.ip].state : 'failed'; });

    const dynIds = new Set();
    hosts.forEach(h => {
      if (h.mac && !CONFIG.declHosts[h.mac.toLowerCase()]) {
        dynIds.add('dyn-' + h.mac.replace(/:/g, ''));
      }
    });

    for (let i = nodes.length - 1; i >= 0; i--) {
      if (nodes[i].dynamic && !dynIds.has(nodes[i].id)) {
        const id = nodes[i].id;
        nodes.splice(i, 1);
        for (let j = links.length - 1; j >= 0; j--) {
          if ((links[j].source.id || links[j].source) === id) links.splice(j, 1);
        }
        changed = true;
      }
    }

    const existing = new Set(nodes.map(n => n.id));
    hosts.forEach(h => {
      if (!h.mac || CONFIG.declHosts[h.mac.toLowerCase()]) return;
      const id = 'dyn-' + h.mac.replace(/:/g, '');
      if (!existing.has(id)) {
        nodes.push({ id: id, type: 'host', label: h.ip, ip: h.ip, mac: h.mac, state: h.state, dynamic: true, bridge: h.bridge });
        if (h.bridge) links.push({ source: id, target: h.bridge });
        changed = true;
      } else {
        const n = nodes.find(n => n.id === id);
        if (n) n.state = h.state;
      }
    });

    checkStateChanges();
    indicator.attr('class', 'indicator ok');
    status.text(getCounts() + ' \u00b7 ' + new Date().toLocaleTimeString());
    render(changed);

    // Traffic animation on links from reachable hosts toward WAN
    const wanNode = nodes.find(n => n.interface);
    const routerNode = nodes.find(n => n.type === 'router');
    const activeLinks = new Set();
    const rank = { host: 0, network: 1, router: 2, external: 3 };

    if (wanNode && routerNode) {
      nodes.filter(n => n.state === 'reachable').forEach(n => {
        const hostLink = links.find(l => (l.source.id || l.source) === n.id || (l.target.id || l.target) === n.id);
        if (hostLink) {
          activeLinks.add(hostLink);
          const bridgeId = (hostLink.source.id || hostLink.source) === n.id ? (hostLink.target.id || hostLink.target) : (hostLink.source.id || hostLink.source);
          const bridgeLink = links.find(l => ((l.source.id || l.source) === bridgeId || (l.target.id || l.target) === bridgeId) &&
                                              ((l.source.id || l.source) === routerNode.id || (l.target.id || l.target) === routerNode.id));
          if (bridgeLink) activeLinks.add(bridgeLink);
        }
        const wanLink = links.find(l => ((l.source.id || l.source) === routerNode.id || (l.target.id || l.target) === routerNode.id) &&
                                         ((l.source.id || l.source) === wanNode.id || (l.target.id || l.target) === wanNode.id));
        if (wanLink) activeLinks.add(wanLink);
      });
    }

    linkOverlayG.selectAll('line').attr('class', d => {
      if (!activeLinks.has(d)) return 'link-overlay';
      const srcRank = rank[d.source.type] ?? 0;
      const tgtRank = rank[d.target.type] ?? 0;
      return srcRank > tgtRank ? 'link-overlay active reverse' : 'link-overlay active';
    });
  } catch (e) {
    indicator.attr('class', 'indicator error');
    status.text('Error \u00b7 retrying...');
    console.error(e);
  }
}

// === Stats Polling ===

async function pollStats() {
  try {
    const res = await fetch('/api/system.json?_=' + Date.now());
    if (res.ok) {
      const sys = await res.json();
      el('val-uptime').textContent = fmtUptime(sys.uptime);

      const loadVal = parseFloat(sys.load[0]);
      const loadEl = el('val-load');
      loadEl.textContent = loadVal.toFixed(2);
      loadEl.className = 'stat-value' + (loadVal > sys.cpu_count ? ' crit' : loadVal > sys.cpu_count * 0.7 ? ' warn' : '');

      const memPct = Math.round((sys.mem_total - sys.mem_available) / sys.mem_total * 100);
      const memEl = el('val-memory');
      memEl.textContent = memPct + '%';
      memEl.className = 'stat-value' + (memPct > 90 ? ' crit' : memPct > 70 ? ' warn' : '');

      const connsEl = el('val-conns');
      connsEl.textContent = sys.connections;
      if (sys.connections_max > 0) {
        const connPct = sys.connections / sys.connections_max * 100;
        connsEl.className = 'stat-value' + (connPct > 90 ? ' crit' : connPct > 70 ? ' warn' : '');
      }
    }
  } catch (e) { /* stats errors are non-critical */ }

  try {
    const res = await fetch('/api/traffic.json?_=' + Date.now());
    if (res.ok) {
      const traf = await res.json();
      const wanName = nodes.find(n => n.interface);
      if (wanName && traf.interfaces) {
        const iface = traf.interfaces.find(i => i.name === wanName.interface);
        if (iface && iface.traffic) {
          const mul = (traf.jsonversion === '2') ? 1 : 1024;
          const day = iface.traffic.day && iface.traffic.day.length ? iface.traffic.day[iface.traffic.day.length - 1] : null;
          if (day) {
            el('val-traffic').textContent = '\u2193' + fmtBytes(day.rx * mul) + ' \u2191' + fmtBytes(day.tx * mul);
          }
        }
      }
    }
  } catch (e) { /* traffic errors are non-critical */ }
}

// === Search ===

let searchTerm = '';

searchInput.addEventListener('input', () => {
  searchTerm = searchInput.value.toLowerCase();
  applySearch();
});

function applySearch() {
  if (!searchTerm) {
    nodeG.selectAll('g.node').classed('dimmed', false);
    linkG.selectAll('line').classed('dimmed', false);
    linkOverlayG.selectAll('line').classed('dimmed', false);
    return;
  }
  const matched = new Set();
  nodeG.selectAll('g.node').classed('dimmed', d => {
    const q = searchTerm;
    const m = d.label.toLowerCase().includes(q) ||
      (d.ip && d.ip.includes(q)) ||
      (d.mac && d.mac.toLowerCase().includes(q)) ||
      d.type.includes(q);
    if (m) matched.add(d.id);
    return !m;
  });
  linkG.selectAll('line').classed('dimmed', d => {
    const src = d.source.id || d.source;
    const tgt = d.target.id || d.target;
    return !matched.has(src) && !matched.has(tgt);
  });
  linkOverlayG.selectAll('line').classed('dimmed', d => {
    const src = d.source.id || d.source;
    const tgt = d.target.id || d.target;
    return !matched.has(src) && !matched.has(tgt);
  });
}

// === Help ===

function toggleHelp() {
  document.getElementById('help').classList.toggle('show');
}

// === Keyboard Shortcuts ===

document.addEventListener('keydown', e => {
  const inSearch = document.activeElement === searchInput;

  if (e.key === 'Escape') {
    if (inSearch) {
      searchInput.value = '';
      searchTerm = '';
      searchInput.blur();
      applySearch();
    }
    document.getElementById('help').classList.remove('show');
    return;
  }

  if (inSearch) return;
  if (e.key === 'c') centerView();
  if (e.key === '/') { e.preventDefault(); searchInput.focus(); }
  if (e.key === '?') toggleHelp();
});

// === Lifecycle ===

render();
setTimeout(centerView, 500);
let pollInterval, statsInterval;

const start = () => {
  poll();
  pollStats();
  pollInterval = setInterval(poll, 5000);
  statsInterval = setInterval(pollStats, 5000);
};

const stop = () => {
  clearInterval(pollInterval);
  clearInterval(statsInterval);
};

document.addEventListener('visibilitychange', () => document.hidden ? stop() : start());
addEventListener('resize', () => svg.attr('width', innerWidth).attr('height', innerHeight));
start();
