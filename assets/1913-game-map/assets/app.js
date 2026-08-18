/**
 * India Political Map - Interactive Vector Application
 * With Rich Heritage, History, Culture, and Arts Modules
 * Built with D3.js, Vanilla JS, and modern SVG rendering
 */

document.addEventListener('DOMContentLoaded', () => {
  // Initialize Lucide Icons
  if (window.lucide) {
    window.lucide.createIcons();
  }

  // Application State
  const state = {
    selectedStateName: null,
    activeZoneFilter: 'all',
    activePalette: 'pastel',
    activeLabelMode: 'code',
    activeBorderWidth: 'ultra-crisp',
    theme: 'light',
    zoomTransform: d3.zoomIdentity,
    isFullscreen: false
  };

  // Color Palette Definitions (Subtle, Muted, Less Intensive for maximum clarity)
  const PALETTES = {
    pastel: {
      name: 'Soft Pastel Harmony',
      colors: ['#D8E2DC', '#FFE5D9', '#FFCAD4', '#E8DFF5', '#D0F4DE', '#FCF6BD'],
      getFill: (d) => {
        const cIdx = d.properties.color_index !== undefined ? d.properties.color_index : 0;
        return PALETTES.pastel.colors[cIdx % PALETTES.pastel.colors.length];
      },
      legend: [
        { label: 'Pastel Tint A (Sage)', color: '#D8E2DC' },
        { label: 'Pastel Tint B (Peach)', color: '#FFE5D9' },
        { label: 'Pastel Tint C (Blush)', color: '#FFCAD4' },
        { label: 'Pastel Tint D (Lavender)', color: '#E8DFF5' }
      ]
    },
    zonal: {
      name: 'Zonal Regions',
      colors: {
        'Northern': '#D6E4FF',
        'Southern': '#D3F4E2',
        'Western': '#FFE2D4',
        'Eastern': '#FEF3C7',
        'Central': '#EBE4F7',
        'North-Eastern': '#CEEBE6',
        'Southern (Islands)': '#CFE9F1'
      },
      getFill: (d) => {
        const zone = d.properties.zone || 'Northern';
        if (d.properties.name.includes('Andaman') || d.properties.name.includes('Lakshadweep')) {
          return PALETTES.zonal.colors['Southern (Islands)'];
        }
        return PALETTES.zonal.colors[zone] || '#D6E4FF';
      },
      legend: [
        { label: 'Northern Zone', color: '#D6E4FF' },
        { label: 'Southern Zone', color: '#D3F4E2' },
        { label: 'Western Zone', color: '#FFE2D4' },
        { label: 'Eastern Zone', color: '#FEF3C7' },
        { label: 'Central Zone', color: '#EBE4F7' },
        { label: 'North-Eastern', color: '#CEEBE6' }
      ]
    },
    cartography: {
      name: 'Editorial Sand & Slate',
      colors: ['#EAE5D9', '#DCE3E1', '#E8DECE', '#DFE5CE', '#EADCD6', '#E2DFD2'],
      getFill: (d) => {
        const cIdx = d.properties.color_index !== undefined ? d.properties.color_index : 0;
        return PALETTES.cartography.colors[cIdx % PALETTES.cartography.colors.length];
      },
      legend: [
        { label: 'Sandstone', color: '#EAE5D9' },
        { label: 'Mineral Slate', color: '#DCE3E1' },
        { label: 'Light Ochre', color: '#E8DECE' },
        { label: 'Olive Mist', color: '#DFE5CE' }
      ]
    },
    monochrome: {
      name: 'Minimal Porcelain',
      colors: ['#F8FAFC', '#F1F5F9', '#E2E8F0', '#CBD5E1'],
      getFill: (d) => {
        const cIdx = d.properties.color_index !== undefined ? d.properties.color_index : 0;
        return PALETTES.monochrome.colors[cIdx % PALETTES.monochrome.colors.length];
      },
      legend: [
        { label: 'Porcelain I', color: '#F8FAFC' },
        { label: 'Porcelain II', color: '#F1F5F9' },
        { label: 'Porcelain III', color: '#E2E8F0' },
        { label: 'Porcelain IV', color: '#CBD5E1' }
      ]
    }
  };

  // Border Width Settings
  const BORDER_WIDTHS = {
    'ultra-crisp': { width: '1.4px', hoverWidth: '2.4px', selectedWidth: '3.0px' },
    'medium': { width: '2.0px', hoverWidth: '3.0px', selectedWidth: '3.6px' },
    'bold': { width: '2.8px', hoverWidth: '3.8px', selectedWidth: '4.4px' }
  };

  // DOM Element References
  const svg = d3.select('#india-map-svg');
  const mapContainer = document.getElementById('map-container');
  const tooltip = document.getElementById('map-tooltip');
  const inspectorPanel = document.getElementById('state-inspector-panel');
  const closeInspectorBtn = document.getElementById('close-inspector-btn');
  const searchInput = document.getElementById('state-search-input');
  const searchDropdown = document.getElementById('search-results-dropdown');
  const searchClearBtn = document.getElementById('search-clear-btn');
  const paletteSelect = document.getElementById('palette-select');
  const labelModeSelect = document.getElementById('label-mode-select');
  const borderWidthSelect = document.getElementById('border-width-select');
  const themeToggleBtn = document.getElementById('theme-toggle-btn');
  const fullscreenBtn = document.getElementById('fullscreen-btn');
  const exportBtn = document.getElementById('export-btn');
  const exportMenu = document.getElementById('export-menu');
  const exportSvgBtn = document.getElementById('export-svg-btn');
  const exportPngBtn = document.getElementById('export-png-btn');
  const printMapBtn = document.getElementById('print-map-btn');
  const zoneChips = document.querySelectorAll('.filter-chips .chip');
  const activeCountText = document.getElementById('active-count-text');
  const legendItemsContainer = document.getElementById('legend-items-container');
  const legendToggleBtn = document.getElementById('legend-toggle-btn');

  // Zoom / Pan Buttons
  const zoomInBtn = document.getElementById('zoom-in-btn');
  const zoomOutBtn = document.getElementById('zoom-out-btn');
  const zoomFitBtn = document.getElementById('zoom-fit-btn');
  const zoomResetBtn = document.getElementById('zoom-reset-btn');

  // Inspector Elements (Overview Tab)
  const inspectName = document.getElementById('inspect-name');
  const inspectCode = document.getElementById('inspect-code');
  const inspectType = document.getElementById('inspect-type');
  const inspectZone = document.getElementById('inspect-zone');
  const inspectCapital = document.getElementById('inspect-capital');
  const inspectPopulation = document.getElementById('inspect-population');
  const inspectArea = document.getElementById('inspect-area');
  const inspectDistricts = document.getElementById('inspect-districts');
  const inspectLanguages = document.getElementById('inspect-languages');
  const inspectNeighbors = document.getElementById('inspect-neighbors');
  const inspectVehicle = document.getElementById('inspect-vehicle');
  const inspectZoomToBtn = document.getElementById('inspect-zoom-to-btn');
  const inspectCopyBtn = document.getElementById('inspect-copy-btn');
  const inspectEnterStoryBtn = document.getElementById('inspect-enter-story-btn');
  const inspectEnterStoryLabel = document.getElementById('inspect-enter-story-label');

  // Inspector Elements (Heritage & Culture Tabs)
  const inspectHistoryText = document.getElementById('inspect-history-text');
  const inspectUnescoList = document.getElementById('inspect-unesco-list');
  const inspectHeritageList = document.getElementById('inspect-heritage-list');
  const inspectDanceTitle = document.getElementById('inspect-dance-title');
  const inspectFestivalsList = document.getElementById('inspect-festivals-list');
  const inspectArtsText = document.getElementById('inspect-arts-text');
  const inspectCuisineText = document.getElementById('inspect-cuisine-text');
  const tabButtons = document.querySelectorAll('.inspector-tabs .tab-btn');
  const tabPanes = document.querySelectorAll('.inspector-body .tab-pane');

  // Tooltip Elements
  const ttCode = document.getElementById('tt-code');
  const ttType = document.getElementById('tt-type');
  const ttZone = document.getElementById('tt-zone');
  const ttName = document.getElementById('tt-name');
  const ttCapital = document.getElementById('tt-capital');
  const ttHeritage = document.getElementById('tt-heritage');
  const ttCulture = document.getElementById('tt-culture');

  // Verify GeoJSON Data is loaded
  if (!window.INDIA_GEOJSON || !window.INDIA_GEOJSON.features) {
    console.error('INDIA_GEOJSON is missing or invalid.');
    showToast('Failed to load map data. Please check data.js.');
    return;
  }

  const geoData = window.INDIA_GEOJSON;

  // D3 Projection and Path Generator
  let width = mapContainer.clientWidth || 900;
  let height = mapContainer.clientHeight || 750;

  const projection = d3.geoMercator()
    .center([82.8, 22.0])
    .scale(1200)
    .translate([width / 2, height / 2]);

  function fitProjection() {
    width = mapContainer.clientWidth || 900;
    height = mapContainer.clientHeight || 750;
    svg.attr('width', width).attr('height', height);

    projection.fitExtent([[40, 40], [width - 40, height - 40]], geoData);
  }

  fitProjection();

  const pathGenerator = d3.geoPath().projection(projection);

  // SVG Groups for Layering
  const gRoot = svg.append('g').attr('class', 'zoom-layer');
  const gStates = gRoot.append('g').attr('class', 'states-layer');
  const gMarkers = gRoot.append('g').attr('class', 'markers-layer');
  const gLabels = gRoot.append('g').attr('class', 'labels-layer');

  // D3 Zoom Behavior
  const zoomBehavior = d3.zoom()
    .scaleExtent([0.8, 12])
    .on('zoom', (event) => {
      state.zoomTransform = event.transform;
      gRoot.attr('transform', event.transform);

      const scale = event.transform.k;
      gLabels.selectAll('.state-label')
        .style('font-size', () => {
          if (state.activeLabelMode === 'code') {
            return `${Math.max(9, 12 / Math.sqrt(scale))}px`;
          } else {
            return `${Math.max(8, 10 / Math.sqrt(scale))}px`;
          }
        });
    });

  svg.call(zoomBehavior);
  svg.on('dblclick.zoom', null);

  // Render State Boundaries
  let statePaths = gStates.selectAll('path.state-path')
    .data(geoData.features)
    .join('path')
    .attr('class', 'state-path')
    .attr('id', (d) => `state-${d.properties.code.toLowerCase()}`)
    .attr('d', pathGenerator)
    .attr('fill', (d) => PALETTES[state.activePalette].getFill(d))
    .attr('data-name', (d) => d.properties.name)
    .attr('data-zone', (d) => d.properties.zone)
    .attr('data-type', (d) => d.properties.type)
    .on('mouseenter', handleStateMouseEnter)
    .on('mousemove', handleStateMouseMove)
    .on('mouseleave', handleStateMouseLeave)
    .on('click', handleStateClick)
    .on('dblclick', (event, d) => {
      event.stopPropagation();
      selectState(d.properties.name);
      launchStateStories(d.properties.name);
    });

  // Render State Labels Layer
  let stateLabels = gLabels.selectAll('text.state-label')
    .data(geoData.features)
    .join('text')
    .attr('class', 'state-label code-label')
    .attr('id', (d) => `label-${d.properties.code.toLowerCase()}`)
    .attr('transform', (d) => {
      const coords = d.properties.label_coords || d3.geoCentroid(d);
      const pt = projection(coords);
      return pt ? `translate(${pt[0]}, ${pt[1]})` : null;
    })
    .text((d) => d.properties.code);

  // Render small UT circles for tiny areas (Chandigarh, Puducherry, Lakshadweep, Daman & Diu, Delhi)
  const tinyUTs = geoData.features.filter(d => ['CH', 'PY', 'LD', 'DD', 'DL'].includes(d.properties.code));
  gMarkers.selectAll('circle.ut-indicator')
    .data(tinyUTs)
    .join('circle')
    .attr('class', 'ut-marker-circle')
    .attr('r', 3)
    .attr('cx', (d) => {
      const coords = d.properties.label_coords || d3.geoCentroid(d);
      const pt = projection(coords);
      return pt ? pt[0] : 0;
    })
    .attr('cy', (d) => {
      const coords = d.properties.label_coords || d3.geoCentroid(d);
      const pt = projection(coords);
      return pt ? pt[1] : 0;
    });

  // Render Active Quest Pins (Tamil Nadu: Bharatanatyam, West Bengal: Netaji)
  const questStates = [
    {
      code: 'TN',
      name: 'Tamil Nadu',
      title: 'Bharatanatyam Quest',
      subtitle: 'Playable Video Level',
      coords: [78.6, 11.2],
      icon: '🎭'
    },
    {
      code: 'WB',
      name: 'West Bengal',
      title: 'Netaji Story',
      subtitle: 'Playable Video Level',
      coords: [87.8, 23.8],
      icon: '⭐'
    }
  ];

  const questPins = gMarkers.selectAll('g.quest-pin-group')
    .data(questStates)
    .join('g')
    .attr('class', 'quest-pin-group')
    .attr('id', d => `quest-pin-${d.code.toLowerCase()}`)
    .attr('transform', d => {
      const pt = projection(d.coords);
      return pt ? `translate(${pt[0]}, ${pt[1]})` : null;
    })
    .on('click', (event, d) => {
      event.stopPropagation();
      selectState(d.name);
      focusState(d.name);
    })
    .on('dblclick', (event, d) => {
      event.stopPropagation();
      selectState(d.name);
      launchStateStories(d.name);
    });

  // Dual Pulsing Auras
  questPins.append('circle')
    .attr('class', 'quest-pulse-ring quest-pulse-1')
    .attr('r', 8);

  questPins.append('circle')
    .attr('class', 'quest-pulse-ring quest-pulse-2')
    .attr('r', 14);

  // Center Badge
  questPins.append('circle')
    .attr('class', 'quest-center-dot')
    .attr('r', 11);

  questPins.append('text')
    .attr('class', 'quest-pin-icon')
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'central')
    .attr('font-size', '11px')
    .text(d => d.icon);

  // Floating Pill Tag
  const questPill = questPins.append('g')
    .attr('class', 'quest-pill-group')
    .attr('transform', 'translate(0, 18)');

  questPill.append('rect')
    .attr('class', 'quest-pill-bg')
    .attr('x', -60)
    .attr('y', -8)
    .attr('width', 120)
    .attr('height', 17)
    .attr('rx', 8.5);

  questPill.append('text')
    .attr('class', 'quest-pill-text')
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'central')
    .attr('font-size', '8px')
    .text(d => d.title.toUpperCase());

  // Initialize UI controls
  updateLegend();
  populateSearchDropdown();
  applyBorderWidth(state.activeBorderWidth);

  // =========================================================================
  // Inspector Tabs Management
  // =========================================================================

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));

      btn.classList.add('active');
      const targetId = btn.getAttribute('data-tab');
      const targetPane = document.getElementById(targetId);
      if (targetPane) {
        targetPane.classList.add('active');
      }
      if (window.lucide) window.lucide.createIcons();
    });
  });

  // =========================================================================
  // State Hover & Click Event Handlers (Anti-Flicker & RAF Throttled)
  // =========================================================================

  let currentHoveredCode = null;
  let rafId = null;

  function handleStateMouseEnter(event, d) {
    const props = d.properties;
    
    if (currentHoveredCode !== props.code) {
      currentHoveredCode = props.code;
      // Update tooltip content
      ttCode.textContent = props.code;
      ttType.textContent = props.type;
      ttZone.textContent = props.zone;
      ttName.textContent = props.name;
      ttCapital.textContent = props.capital;

      // First UNESCO / Heritage landmark
      const topHeritage = (props.unesco_sites && props.unesco_sites.length > 0) 
        ? props.unesco_sites[0].replace(/\(.*?\)/g, '').trim()
        : (props.heritage_sites && props.heritage_sites.length > 0 ? props.heritage_sites[0] : 'Historical Architecture');
      
      ttHeritage.textContent = topHeritage;

      // Culture snippet
      const dance = props.dance_music ? props.dance_music.split(',')[0].trim() : 'Classical / Folk arts';
      ttCulture.textContent = dance;
    }

    tooltip.style.opacity = '1';
    positionTooltip(event);
  }

  function handleStateMouseMove(event) {
    if (rafId) cancelAnimationFrame(rafId);
    rafId = requestAnimationFrame(() => {
      positionTooltip(event);
    });
  }

  function positionTooltip(event) {
    const pad = 18;
    let x = event.clientX;
    let y = event.clientY - pad;

    const ttRect = tooltip.getBoundingClientRect();
    if (x - ttRect.width / 2 < 10) x = ttRect.width / 2 + 10;
    if (x + ttRect.width / 2 > window.innerWidth - 10) x = window.innerWidth - ttRect.width / 2 - 10;
    if (y - ttRect.height < 60) y = event.clientY + 32;

    tooltip.style.left = `${x}px`;
    tooltip.style.top = `${y}px`;
  }

  function handleStateMouseLeave() {
    currentHoveredCode = null;
    if (rafId) cancelAnimationFrame(rafId);
    tooltip.style.opacity = '0';
  }

  function handleStateClick(event, d) {
    selectState(d.properties.name);
  }

  // Select State and display Inspector Drawer with Deep Heritage Data
  function selectState(stateName) {
    const feature = geoData.features.find(f => f.properties.name === stateName);
    if (!feature) return;

    state.selectedStateName = stateName;
    const props = feature.properties;

    // Highlight path
    statePaths.classed('selected', d => d.properties.name === stateName);

    // Update Header
    inspectName.textContent = props.name;
    inspectCode.textContent = props.code;
    inspectType.textContent = props.type;
    inspectZone.textContent = `${props.zone} Zone`;
    if (inspectEnterStoryLabel) {
      inspectEnterStoryLabel.textContent = `Explore ${props.name} Stories`;
    }

    // TAB 1: OVERVIEW
    inspectCapital.textContent = props.capital;
    inspectPopulation.textContent = props.population;
    inspectArea.textContent = props.area;
    inspectDistricts.textContent = props.districts;
    inspectVehicle.textContent = props.vehicle_code;

    // Languages Tags
    inspectLanguages.innerHTML = '';
    const langs = (props.language || 'Hindi, English').split(',').map(s => s.trim());
    langs.forEach(lang => {
      const tag = document.createElement('span');
      tag.className = 'tag';
      tag.textContent = lang;
      inspectLanguages.appendChild(tag);
    });

    // Neighbors Pills
    inspectNeighbors.innerHTML = '';
    const neighbors = props.neighbors || [];
    if (neighbors.length > 0) {
      neighbors.forEach(nbrName => {
        const chip = document.createElement('button');
        chip.className = 'neighbor-chip';
        chip.textContent = nbrName;
        chip.title = `Jump to ${nbrName}`;
        chip.addEventListener('click', () => {
          selectState(nbrName);
          focusState(nbrName);
        });
        inspectNeighbors.appendChild(chip);
      });
    } else {
      const noNbr = document.createElement('span');
      noNbr.className = 'tag';
      noNbr.textContent = 'Island / Coastline (No land neighbors)';
      inspectNeighbors.appendChild(noNbr);
    }

    // TAB 2: HISTORY & UNESCO SITES
    inspectHistoryText.textContent = props.history || 'Rich ancient and medieval heritage with deep dynastic chronicles.';

    // UNESCO Sites list
    inspectUnescoList.innerHTML = '';
    const unescoSites = props.unesco_sites || [];
    if (unescoSites.length > 0) {
      unescoSites.forEach(site => {
        const isTentative = site.toLowerCase().includes('tentative');
        const badge = document.createElement('div');
        badge.className = `unesco-badge ${isTentative ? 'tentative' : 'official'}`;
        badge.innerHTML = `
          <span class="unesco-star">${isTentative ? '⏳' : '⭐'}</span>
          <div>
            <strong>${site}</strong>
            <div style="font-size: 0.7rem; color: inherit; opacity: 0.85;">${isTentative ? 'UNESCO Tentative List' : 'Inscribed UNESCO World Heritage Site'}</div>
          </div>
        `;
        inspectUnescoList.appendChild(badge);
      });
    } else {
      const noneBadge = document.createElement('div');
      noneBadge.className = 'unesco-badge tentative';
      noneBadge.textContent = 'Protected monuments under State and ASI preservation.';
      inspectUnescoList.appendChild(noneBadge);
    }

    // Heritage Monuments
    inspectHeritageList.innerHTML = '';
    const heritageMonuments = props.heritage_sites || [];
    heritageMonuments.forEach(monument => {
      const li = document.createElement('li');
      li.textContent = monument;
      inspectHeritageList.appendChild(li);
    });

    // TAB 3: CULTURE & ARTS
    inspectDanceTitle.textContent = props.dance_music || 'Vibrant folk and classical traditions';
    
    inspectFestivalsList.innerHTML = '';
    const festivals = props.festivals || [];
    festivals.forEach(fest => {
      const tag = document.createElement('span');
      tag.className = 'tag';
      tag.textContent = fest;
      inspectFestivalsList.appendChild(tag);
    });

    inspectArtsText.textContent = props.arts_crafts || 'Traditional handlooms, pottery, and indigenous handicrafts.';

    // TAB 4: CUISINE
    inspectCuisineText.textContent = props.cuisine || 'Traditional authentic regional gastronomy and GI-tagged delicacies.';

    // Re-render lucide icons inside inspector
    if (window.lucide) {
      window.lucide.createIcons();
    }

    // Open Inspector Drawer
    inspectorPanel.classList.remove('collapsed');

    // Hide search dropdown if open
    searchDropdown.style.display = 'none';
  }

  // Smoothly Zoom & Focus on State
  function focusState(stateName) {
    const feature = geoData.features.find(f => f.properties.name === stateName);
    if (!feature) return;

    const bounds = pathGenerator.bounds(feature);
    const dx = bounds[1][0] - bounds[0][0];
    const dy = bounds[1][1] - bounds[0][1];
    const x = (bounds[0][0] + bounds[1][0]) / 2;
    const y = (bounds[0][1] + bounds[1][1]) / 2;

    const scale = Math.max(1, Math.min(6, 0.7 / Math.max(dx / width, dy / height)));
    const translate = [width / 2 - scale * x, height / 2 - scale * y];

    svg.transition()
      .duration(750)
      .call(
        zoomBehavior.transform,
        d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale)
      );
  }

  // Close Inspector Drawer
  closeInspectorBtn.addEventListener('click', () => {
    inspectorPanel.classList.add('collapsed');
    state.selectedStateName = null;
    statePaths.classed('selected', false);
  });

  function getNormalizedStateId(name) {
    if (!name) return 'west_bengal';
    const clean = name.toLowerCase().trim().replace(/[^a-z0-9]/g, '_').replace(/_+/g, '_');
    if (clean.includes('bengal') || clean.includes('calcutta') || clean.includes('kolkata')) return 'west_bengal';
    if (clean.includes('tamil') || clean.includes('chennai') || clean.includes('madras')) return 'tamil_nadu';
    return clean;
  }

  function launchStateStories(stateName) {
    const sName = stateName || state.selectedStateName || 'West Bengal';
    const stateId = getNormalizedStateId(sName);
    
    // Retrieve state metadata from GeoJSON
    const feature = geoData.features.find(f => f.properties.name.toLowerCase() === sName.toLowerCase());
    const props = feature ? feature.properties : {};
    const code = props.code || '';
    const dance = props.dance_music || '';
    
    const payload = JSON.stringify({
      action: 'open_state',
      stateId: stateId,
      stateName: sName,
      stateCode: code,
      dance: dance
    });

    console.log('Sending state story message to Flutter:', payload);

    // 1. Post message to Flutter Web parent iframe
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(payload, '*');
      window.parent.postMessage(`open_state_${stateId}`, '*');
      if (stateId === 'west_bengal') {
        window.parent.postMessage('open_calcutta', '*');
      }
    }
    
    // 2. Post message to Flutter Windows Webview2
    if (window.chrome && window.chrome.webview) {
      window.chrome.webview.postMessage(payload);
    }
  }

  if (inspectEnterStoryBtn) {
    inspectEnterStoryBtn.addEventListener('click', () => {
      launchStateStories(state.selectedStateName);
    });
  }

  inspectZoomToBtn.addEventListener('click', () => {
    if (state.selectedStateName) {
      focusState(state.selectedStateName);
    }
  });

  inspectCopyBtn.addEventListener('click', () => {
    if (!state.selectedStateName) return;
    const feature = geoData.features.find(f => f.properties.name === state.selectedStateName);
    if (!feature) return;
    const p = feature.properties;
    const text = `===========================================
BHĀRAT PROFILE: ${p.name.toUpperCase()} (${p.type})
===========================================
• Capital: ${p.capital}
• Zone: ${p.zone} Zone
• Area: ${p.area} | Population: ${p.population} | Districts: ${p.districts}
• Official Languages: ${p.language}
• Vehicle Code: ${p.vehicle_code}

🏛️ HISTORICAL SIGNIFICANCE:
${p.history}

⭐ UNESCO & ICONIC HERITAGE SITES:
${(p.unesco_sites || []).join(', ')}
${(p.heritage_sites || []).join(', ')}

🎭 DANCE, MUSIC & CULTURE:
• Dance & Music: ${p.dance_music}
• Major Festivals: ${(p.festivals || []).join(', ')}
• Traditional Arts & Handlooms: ${p.arts_crafts}

🍲 GASTRONOMY & CUISINE:
${p.cuisine}
===========================================`;

    navigator.clipboard.writeText(text).then(() => {
      showToast(`Copied complete heritage profile of ${p.name}!`);
    });
  });

  // =========================================================================
  // Palette & Styling Management
  // =========================================================================

  paletteSelect.addEventListener('change', (e) => {
    state.activePalette = e.target.value;
    document.body.setAttribute('data-palette', state.activePalette);
    
    statePaths.transition().duration(300)
      .attr('fill', (d) => PALETTES[state.activePalette].getFill(d));

    updateLegend();
  });

  function updateLegend() {
    const curPalette = PALETTES[state.activePalette];
    legendItemsContainer.innerHTML = '';

    if (curPalette && curPalette.legend) {
      curPalette.legend.forEach(item => {
        const div = document.createElement('div');
        div.className = 'legend-item';
        div.innerHTML = `
          <span class="legend-color-box" style="background-color: ${item.color};"></span>
          <span>${item.label}</span>
        `;
        legendItemsContainer.appendChild(div);
      });
    }
  }

  // Minimize / Restore Legend
  legendToggleBtn.addEventListener('click', () => {
    const isHidden = legendItemsContainer.style.display === 'none';
    legendItemsContainer.style.display = isHidden ? 'grid' : 'none';
    legendToggleBtn.innerHTML = isHidden ? '&minus;' : '+';
  });

  // Label Mode Switching
  labelModeSelect.addEventListener('change', (e) => {
    state.activeLabelMode = e.target.value;

    if (state.activeLabelMode === 'none') {
      stateLabels.style('opacity', 0);
    } else if (state.activeLabelMode === 'code') {
      stateLabels
        .style('opacity', 1)
        .attr('class', 'state-label code-label')
        .text(d => d.properties.code);
    } else if (state.activeLabelMode === 'name') {
      stateLabels
        .style('opacity', 1)
        .attr('class', 'state-label name-label')
        .text(d => d.properties.name);
    }
  });

  // Border Width Clarity
  borderWidthSelect.addEventListener('change', (e) => {
    state.activeBorderWidth = e.target.value;
    applyBorderWidth(state.activeBorderWidth);
  });

  function applyBorderWidth(setting) {
    const config = BORDER_WIDTHS[setting] || BORDER_WIDTHS['ultra-crisp'];
    document.documentElement.style.setProperty('--map-border-width', config.width);
    document.documentElement.style.setProperty('--map-border-hover-width', config.hoverWidth);
    document.documentElement.style.setProperty('--map-border-selected-width', config.selectedWidth);
  }

  // =========================================================================
  // Zone Filtering
  // =========================================================================

  zoneChips.forEach(chip => {
    chip.addEventListener('click', () => {
      zoneChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');

      const selectedZone = chip.getAttribute('data-zone');
      state.activeZoneFilter = selectedZone;

      filterByZone(selectedZone);
    });
  });

  function filterByZone(zone) {
    let matchCount = 0;

    if (zone === 'all') {
      statePaths.classed('dimmed', false);
      stateLabels.classed('dimmed', false);
      matchCount = geoData.features.length;
      activeCountText.textContent = `Showing all ${matchCount} Entities`;
    } else if (zone === 'Union Territory') {
      statePaths.classed('dimmed', d => d.properties.type !== 'Union Territory');
      stateLabels.classed('dimmed', d => d.properties.type !== 'Union Territory');
      matchCount = geoData.features.filter(d => d.properties.type === 'Union Territory').length;
      activeCountText.textContent = `Showing ${matchCount} Union Territories`;
    } else {
      statePaths.classed('dimmed', d => d.properties.zone !== zone);
      stateLabels.classed('dimmed', d => d.properties.zone !== zone);
      matchCount = geoData.features.filter(d => d.properties.zone === zone).length;
      activeCountText.textContent = `Showing ${matchCount} States in ${zone} Zone`;
    }
  }

  // =========================================================================
  // Deep Search & Autocomplete (State, Capital, UNESCO, Festival, Dance)
  // =========================================================================

  function populateSearchDropdown() {
    searchDropdown.innerHTML = '';
    const items = geoData.features.map(f => f.properties);

    items.sort((a, b) => a.name.localeCompare(b.name));

    items.forEach(item => {
      const div = document.createElement('div');
      div.className = 'search-item';
      div.setAttribute('data-name', item.name);
      
      const topSite = (item.unesco_sites && item.unesco_sites.length > 0)
        ? item.unesco_sites[0].replace(/\(.*?\)/g, '').trim()
        : (item.heritage_sites && item.heritage_sites.length > 0 ? item.heritage_sites[0] : '');

      div.innerHTML = `
        <div>
          <div class="search-item-title">${item.name}</div>
          <div class="search-item-sub">Capital: ${item.capital} &bull; ${item.zone}</div>
          ${topSite ? `<div class="search-item-match-pill">🏛️ ${topSite}</div>` : ''}
        </div>
        <span class="search-item-badge">${item.code}</span>
      `;

      div.addEventListener('click', () => {
        searchInput.value = item.name;
        searchDropdown.style.display = 'none';
        searchClearBtn.style.display = 'flex';
        selectState(item.name);
        focusState(item.name);
      });

      searchDropdown.appendChild(div);
    });
  }

  searchInput.addEventListener('input', (e) => {
    const val = e.target.value.trim().toLowerCase();
    searchClearBtn.style.display = val.length > 0 ? 'flex' : 'none';

    if (val.length === 0) {
      searchDropdown.style.display = 'none';
      return;
    }

    const items = searchDropdown.querySelectorAll('.search-item');
    let visibleCount = 0;

    items.forEach(el => {
      const name = el.getAttribute('data-name');
      const feature = geoData.features.find(f => f.properties.name === name);
      if (!feature) return;

      const p = feature.properties;
      
      // Deep matching across Name, Capital, Code, Zone, UNESCO sites, Heritage sites, Festivals, Dance, Cuisine
      const heritageString = (p.heritage_sites || []).join(' ').toLowerCase();
      const unescoString = (p.unesco_sites || []).join(' ').toLowerCase();
      const festString = (p.festivals || []).join(' ').toLowerCase();
      const danceString = (p.dance_music || '').toLowerCase();
      const artsString = (p.arts_crafts || '').toLowerCase();

      const matches = p.name.toLowerCase().includes(val) ||
                      p.capital.toLowerCase().includes(val) ||
                      p.code.toLowerCase() === val ||
                      p.zone.toLowerCase().includes(val) ||
                      heritageString.includes(val) ||
                      unescoString.includes(val) ||
                      festString.includes(val) ||
                      danceString.includes(val) ||
                      artsString.includes(val);

      el.style.display = matches ? 'flex' : 'none';
      if (matches) visibleCount++;
    });

    searchDropdown.style.display = visibleCount > 0 ? 'block' : 'none';
  });

  searchClearBtn.addEventListener('click', () => {
    searchInput.value = '';
    searchDropdown.style.display = 'none';
    searchClearBtn.style.display = 'none';
    searchInput.focus();
  });

  // Global Keyboard Shortcut: Ctrl + K or '/' to focus search
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey && e.key === 'k') || (e.key === '/' && document.activeElement !== searchInput)) {
      e.preventDefault();
      searchInput.focus();
      searchInput.select();
    } else if (e.key === 'Escape') {
      searchDropdown.style.display = 'none';
      inspectorPanel.classList.add('collapsed');
      state.selectedStateName = null;
      statePaths.classed('selected', false);
    }
  });

  // Hide search dropdown on click outside
  document.addEventListener('click', (e) => {
    if (!searchInput.contains(e.target) && !searchDropdown.contains(e.target)) {
      searchDropdown.style.display = 'none';
    }
    if (!exportBtn.contains(e.target) && !exportMenu.contains(e.target)) {
      exportMenu.classList.remove('show');
    }
  });

  // =========================================================================
  // Zoom & Pan Navigation Controls
  // =========================================================================

  zoomInBtn.addEventListener('click', () => {
    svg.transition().duration(300).call(zoomBehavior.scaleBy, 1.35);
  });

  zoomOutBtn.addEventListener('click', () => {
    svg.transition().duration(300).call(zoomBehavior.scaleBy, 0.74);
  });

  zoomFitBtn.addEventListener('click', () => {
    fitProjection();
    svg.transition().duration(600).call(zoomBehavior.transform, d3.zoomIdentity);
  });

  zoomResetBtn.addEventListener('click', () => {
    svg.transition().duration(600).call(zoomBehavior.transform, d3.zoomIdentity);
  });

  // Handle Window Resize
  window.addEventListener('resize', () => {
    fitProjection();
    pathGenerator.projection(projection);
    statePaths.attr('d', pathGenerator);
    stateLabels.attr('transform', (d) => {
      const coords = d.properties.label_coords || d3.geoCentroid(d);
      const pt = projection(coords);
      return pt ? `translate(${pt[0]}, ${pt[1]})` : null;
    });
  });

  // =========================================================================
  // Theme & Fullscreen Controls
  // =========================================================================

  themeToggleBtn.addEventListener('click', () => {
    state.theme = state.theme === 'light' ? 'dark' : 'light';
    document.body.setAttribute('data-theme', state.theme);
    
    statePaths.attr('fill', (d) => PALETTES[state.activePalette].getFill(d));
    showToast(`Switched to ${state.theme === 'dark' ? 'Dark' : 'Light'} Mode`);
  });

  fullscreenBtn.addEventListener('click', () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().then(() => {
        state.isFullscreen = true;
      });
    } else {
      document.exitFullscreen().then(() => {
        state.isFullscreen = false;
      });
    }
  });

  // =========================================================================
  // Export & Print Capabilities
  // =========================================================================

  exportBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    exportMenu.classList.toggle('show');
  });

  // Export Vector SVG
  exportSvgBtn.addEventListener('click', () => {
    exportMenu.classList.remove('show');
    
    const svgElement = document.getElementById('india-map-svg');
    const serializer = new XMLSerializer();
    let source = serializer.serializeToString(svgElement);

    if (!source.match(/^<svg[^>]+xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)) {
      source = source.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
    }

    const blob = new Blob([source], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'India_Political_Heritage_Map.svg';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    showToast('Vector SVG Map exported!');
  });

  // Export High-Resolution PNG
  exportPngBtn.addEventListener('click', () => {
    exportMenu.classList.remove('show');
    showToast('Generating High-Res PNG...');

    const svgElement = document.getElementById('india-map-svg');
    const svgBounds = svgElement.getBoundingClientRect();
    const serializer = new XMLSerializer();
    const source = serializer.serializeToString(svgElement);

    const canvas = document.createElement('canvas');
    const scale = 2; // 2x resolution for high sharpness
    canvas.width = svgBounds.width * scale;
    canvas.height = svgBounds.height * scale;
    const ctx = canvas.getContext('2d');
    ctx.scale(scale, scale);

    ctx.fillStyle = state.theme === 'dark' ? '#0B0F17' : '#F8FAFC';
    ctx.fillRect(0, 0, svgBounds.width, svgBounds.height);

    const img = new Image();
    const svgBlob = new Blob([source], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(svgBlob);

    img.onload = () => {
      ctx.drawImage(img, 0, 0, svgBounds.width, svgBounds.height);
      URL.revokeObjectURL(url);

      const pngUrl = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.href = pngUrl;
      link.download = 'India_Political_Heritage_Map_HD.png';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      showToast('High-Res PNG downloaded successfully!');
    };
    img.src = url;
  });

  // Print Map
  printMapBtn.addEventListener('click', () => {
    exportMenu.classList.remove('show');
    window.print();
  });

  // =========================================================================
  // Toast Helper
  // =========================================================================

  function showToast(message) {
    const toast = document.getElementById('toast');
    const toastMsg = document.getElementById('toast-message');
    toastMsg.textContent = message;
    toast.style.display = 'flex';

    if (window.toastTimeout) clearTimeout(window.toastTimeout);
    window.toastTimeout = setTimeout(() => {
      toast.style.display = 'none';
    }, 2800);
  }
});
