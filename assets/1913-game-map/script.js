// Game Map State
let currentSelectedCity = null;

// The two main interactive locations for the game
const cities = [
    {
        id: "cambridge",
        name: "CAMBRIDGE",
        desc: "England",
        coords: [0.1218, 52.2053], // Longitude, Latitude
        labelOffset: [-45, -15]
    },
    {
        id: "calcutta",
        name: "CALCUTTA",
        desc: "Capital of British India",
        coords: [88.3639, 22.5726],
        labelOffset: [15, 15]
    }
];

// Connection route between the two cities
const route = {
    type: "LineString",
    coordinates: cities.map(c => c.coords)
};

// Initialize the Map
function initMap() {
    const container = document.querySelector('.map-container');
    const width = container.clientWidth;
    const height = container.clientHeight;

    const svg = d3.select("#world-map");
    const g = svg.append("g");

    // We use geoNaturalEarth1 for a classic, aesthetic world map projection
    const projection = d3.geoNaturalEarth1()
        .scale(width / 5)
        .translate([width / 2, height / 2.2]); // Slightly offset to fit the UI

    const path = d3.geoPath().projection(projection);

    // Zoom and pan capabilities
    const zoom = d3.zoom()
        .scaleExtent([1, 6])
        .on("zoom", (event) => {
            g.attr("transform", event.transform);
        });
    svg.call(zoom);

    // Fetch the 1914 historical world map GeoJSON (closest accurate representation to 1913)
    d3.json("https://raw.githubusercontent.com/aourednik/historical-basemaps/master/geojson/world_1914.geojson")
        .then(data => {
            // 1. Draw the landmasses
            g.selectAll("path.country")
                .data(data.features)
                .enter()
                .append("path")
                .attr("class", "country")
                .attr("d", path);

            // 2. Draw the connecting travel route
            g.append("path")
                .datum(route)
                .attr("class", "route-line")
                .attr("id", "travel-route")
                .attr("d", path);

            // 3. Draw the interactive cities
            const cityNodes = g.selectAll(".city-node")
                .data(cities)
                .enter()
                .append("g")
                .attr("class", "city-node")
                .attr("id", d => `node-${d.id}`)
                .attr("transform", d => {
                    const [x, y] = projection(d.coords);
                    return `translate(${x},${y})`;
                })
                .on("click", (event, d) => handleCityClick(event, d));

            // Pulsing aura
            cityNodes.append("circle")
                .attr("class", "city-pulse")
                .attr("r", 6);

            // Vintage Marker background
            cityNodes.append("circle")
                .attr("class", "city-marker-bg")
                .attr("r", 8);

            // Marker inner dot
            cityNodes.append("circle")
                .attr("class", "city-marker-dot")
                .attr("r", 3);

            // 4. Hover Labels
            const labelGroup = cityNodes.append("g")
                .attr("transform", d => `translate(${d.labelOffset[0]}, ${d.labelOffset[1]})`);
            
            // Label background
            labelGroup.append("rect")
                .attr("class", "city-label-bg")
                .attr("x", -5)
                .attr("y", -14)
                .attr("width", 90)
                .attr("height", 20);
                
            // Label text
            labelGroup.append("text")
                .attr("class", "city-label-text")
                .text(d => d.name);

        })
        .catch(err => console.error("Error loading historical map data:", err));

    // Handle Window Resizing to keep map responsive
    window.addEventListener('resize', () => {
        const newWidth = container.clientWidth;
        const newHeight = container.clientHeight;
        
        projection.translate([newWidth / 2, newHeight / 2.2]);
        
        g.selectAll("path.country").attr("d", path);
        g.select(".route-line").attr("d", path);
        g.selectAll(".city-node").attr("transform", d => {
            const [x, y] = projection(d.coords);
            return `translate(${x},${y})`;
        });
    });

    // Close popup if clicking on empty ocean
    svg.on("click", (event) => {
        if (event.target.tagName === 'svg') {
            closePopup();
        }
    });
}

// INTERACTION LOGIC

function handleCityClick(event, city) {
    event.stopPropagation(); // Prevent SVG click from firing
    
    currentSelectedCity = city;

    // Reset highlights
    d3.selectAll('.city-node').classed('highlight', false);
    d3.select('#travel-route').classed('highlight', false);

    // Add highlight to clicked city and route
    d3.select(`#node-${city.id}`).classed('highlight', true);
    d3.select('#travel-route').classed('highlight', true);

    // Update UI Popup Card
    document.getElementById('popup-title').innerText = city.name;
    document.getElementById('popup-desc').innerText = city.desc;
    
    // Show popup
    document.getElementById('location-popup').classList.remove('hidden');
}

function closePopup() {
    currentSelectedCity = null;
    document.getElementById('location-popup').classList.add('hidden');
    d3.selectAll('.city-node').classed('highlight', false);
    d3.select('#travel-route').classed('highlight', false);
}

// Button Click Action
function enterLocation() {
    if (currentSelectedCity) {
        if (currentSelectedCity.id === 'calcutta') {
            window.location.href = 'calcutta.html';
        } else {
            alert(`Entering ${currentSelectedCity.name}...\nLoading historical scenario...`);
        }
    }
}

// Initialize on load
document.addEventListener("DOMContentLoaded", initMap);
