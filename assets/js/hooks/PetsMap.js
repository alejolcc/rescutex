const PetsMap = {
    mounted() {
        this.initMap();
    },

    async initMap() {
        const position = { lat: -32.9559518, lng: -60.660833 };
        const { Map } = await google.maps.importLibrary("maps");
        const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");


        const map = new Map(this.el, {
            zoom: 12,
            center: position,
            mapId: "PETS_MAP_ID",
        });

        this.handleEvent("update-markers", ({ pets }) => {
            this.addMarkers(map, pets, AdvancedMarkerElement, PinElement);
        });

        this.pushEvent("update-markers");
    },

    addMarkers(map, pets, AdvancedMarkerElement, PinElement) {
        const infoWindow = new google.maps.InfoWindow();

        // It's good practice to close the info window if the map is clicked
        map.addListener('click', () => {
            infoWindow.close();
        });

        const markers = pets.map(pet => {
            const pinBackground = this.createPinForPet(pet.post_type, PinElement);

            const marker = new AdvancedMarkerElement({
                position: { lat: pet.lat, lng: pet.long },
                content: pinBackground.element,
                gmpClickable: true,
                title: `Status: ${pet.post_type}`
            });

            // Use 'gmp-click' for AdvancedMarkerElement, as it's the recommended event
            marker.addListener('gmp-click', () => {
                // Build the rich HTML content for the InfoWindow
                const contentString = `
                <div style="display: flex; font-family: sans-serif; max-width: 280px;">
                    
                    <img 
                        src="${pet.image_url || 'https://via.placeholder.com/150'}" 
                        alt="${pet.name || 'Pet'}"
                        style="width: 96px; height: 96px; object-fit: cover; border-radius: 0.5rem; margin-right: 12px;"
                    >
                    
                    <div style="display: flex; flex-direction: column;">
                        <h3 style="font-weight: 700; font-size: 1.125rem; margin: 0 0 4px 0;">
                            ${pet.name || 'Pet'}
                        </h3>
                        <p style="margin: 0 0 8px 0; font-size: 0.875rem;">
                            <strong>Status:</strong> ${this.formatPostType(pet.post_type)}
                        </p>
                        <a 
                            href="/pets/${pet.id}" 
                            style="display: inline-block; padding: 6px 12px; background-color: #3B82F6; color: white; text-align: center; text-decoration: none; border-radius: 0.375rem; font-size: 0.875rem;"
                        >
                            View Profile
                        </a>
                    </div>
                </div>
            `;

                infoWindow.setContent(contentString);
                infoWindow.open(map, marker);
            });

            // 2. Add a 'mouseover' event listener to the marker's content element
            marker.content.addEventListener('mouseover', () => {
                // Make the pin larger on hover
                pinBackground.scale = 1.5;

                // Build the rich HTML content for the InfoWindow
                const contentString = `
                <div style="display: flex; font-family: sans-serif; max-width: 280px;">
                    
                    <img 
                        src="${pet.image_url || 'https://via.placeholder.com/150'}" 
                        alt="${pet.name || 'Pet'}"
                        style="width: 96px; height: 96px; object-fit: cover; border-radius: 0.5rem; margin-right: 12px;"
                    >
                    
                    <div style="display: flex; flex-direction: column;">
                        <h3 style="font-weight: 700; font-size: 1.125rem; margin: 0 0 4px 0;">
                            ${pet.name || 'Pet'}
                        </h3>
                        <p style="margin: 0 0 8px 0; font-size: 0.875rem;">
                            <strong>Status:</strong> ${this.formatPostType(pet.post_type)}
                        </p>
                        <a 
                            href="/pets/${pet.id}" 
                            style="display: inline-block; padding: 6px 12px; background-color: #3B82F6; color: white; text-align: center; text-decoration: none; border-radius: 0.375rem; font-size: 0.875rem;"
                        >
                            View Profile
                        </a>
                    </div>
                </div>
            `;

                infoWindow.setContent(contentString);
                infoWindow.open(map, marker);
            });

            // 3. Add a 'mouseout' event listener to reset the style
            marker.content.addEventListener('mouseout', () => {
                // Reset the pin's scale
                pinBackground.scale = 1;

                // Close the infoWindow
                // infoWindow.close();
            });

            // Your existing click listener
            marker.addListener('click', () => {
                console.log("Marker clicked! Navigating to pet page...");
                // Example of how you might push an event back to the server (if using Phoenix LiveView)
                // this.pushEvent("show-pet-details", { id: pet.id });
            });

            return marker
        });

        new markerClusterer.MarkerClusterer({ markers, map });
    },

    // A small helper function to make the post_type more readable
    formatPostType(postType) {
        if (!postType) return 'Unknown';
        return postType.charAt(0).toUpperCase() + postType.slice(1);
    },

    // Change the pin depend on the post_type
    createPinForPet(postType, PinElement) {
        let pinBackground;

        switch (postType) {
            case "lost":
                pinBackground = new PinElement({
                    background: "#FF5722",
                    glyph: '',
                });
                break;
            case "found":
                pinBackground = new PinElement({
                    background: "#34A853", // green-400
                    glyph: '',
                });
                break;
            case "adoption":
                pinBackground = new PinElement({
                    background: "#8E44AD",
                    glyph: '',
                });
                break;
            case "transit":
                pinBackground = new PinElement({
                    background: "#3498DB",
                    glyph: '',
                });
                break;
            default:
                pinBackground = new PinElement({
                    background: "#1ABC9C",
                    glyph: '',
                });
        }
        return pinBackground;
    }
};

export default PetsMap;