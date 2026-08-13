/**
 * Calcutta Historical Archive Module
 * Interactive archive screen for 1913 Heritage Game Map.
 * Configured for future game level expansion.
 */

// Historical Archive Dataset
const archiveItems = [
    {
        id: "1916",
        period: "1916",
        location: "CALCUTTA",
        image: "assets/calcutta-1916.jpg",
        desc: "Calcutta in 1916 — Early electric tramways, Harrison Road, Clive Street, and classic British Raj era architecture.",
        // Future Game Structure: Set to 'calcutta-1916.html' when level page is added
        targetUrl: null 
    },
    {
        id: "1921-1941",
        period: "1921–1941",
        location: "CALCUTTA",
        image: "assets/calcutta-1921-1941.jpg",
        desc: "Calcutta from 1921 to 1941 — Dalhousie Square, classic vintage automobiles, Howrah riverfront and interwar civic life.",
        // Future Game Structure: Set to 'calcutta-1921.html' when level page is added
        targetUrl: null 
    }
];

// Initialize Interactive Archive Handlers
document.addEventListener("DOMContentLoaded", () => {
    initArchiveCards();
    initLightboxListeners();
});

/**
 * Attaches event listeners to historical archive cards
 */
function initArchiveCards() {
    archiveItems.forEach(item => {
        const cardElement = document.getElementById(`card-${item.id}`);
        if (!cardElement) return;

        // Card Click Handler
        cardElement.addEventListener("click", () => handleCardAction(item));

        // Accessibility Keyboard Navigation (Enter or Space key)
        cardElement.addEventListener("keydown", (event) => {
            if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                handleCardAction(item);
            }
        });
    });
}

/**
 * Handles card activation - either redirects to level page or opens archival lightbox
 */
function handleCardAction(item) {
    if (item.targetUrl) {
        // Future level navigation support
        window.location.href = item.targetUrl;
    } else {
        // Open historical photo lightbox
        openLightbox(item);
    }
}

/**
 * Opens the photo lightbox modal with details for the selected period
 */
function openLightbox(item) {
    const lightbox = document.getElementById("photo-lightbox");
    const imgElem = document.getElementById("lightbox-img");
    const yearElem = document.getElementById("lightbox-year");
    const locationElem = document.getElementById("lightbox-location");
    const descElem = document.getElementById("lightbox-desc");

    if (!lightbox || !imgElem) return;

    imgElem.src = item.image;
    imgElem.alt = `Archival photograph of Calcutta (${item.period})`;
    yearElem.innerText = item.period;
    locationElem.innerText = item.location;
    descElem.innerText = item.desc;

    lightbox.classList.remove("hidden");
}

/**
 * Closes the photo lightbox modal
 */
function closeLightbox() {
    const lightbox = document.getElementById("photo-lightbox");
    if (lightbox) {
        lightbox.classList.add("hidden");
    }
}

/**
 * Initializes close button, overlay click, and Escape key listeners
 */
function initLightboxListeners() {
    const lightbox = document.getElementById("photo-lightbox");
    const closeBtn = document.getElementById("lightbox-close");

    if (closeBtn) {
        closeBtn.addEventListener("click", (e) => {
            e.stopPropagation();
            closeLightbox();
        });
    }

    if (lightbox) {
        // Close when clicking overlay outside the photo modal box
        lightbox.addEventListener("click", (event) => {
            if (event.target === lightbox) {
                closeLightbox();
            }
        });
    }

    // Support keyboard ESC key to close lightbox
    document.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
            closeLightbox();
        }
    });
}
