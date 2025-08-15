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
        const markers = pets.map(pet => {
            const pinBackground = this.createPinForPet(pet.post_type, PinElement);

            const marker = new AdvancedMarkerElement({
                position: { lat: pet.lat, lng: pet.long },
                content: pinBackground.element,
                gmpClickable: true,
            });

            // 2. Add a 'mouseover' event listener to the marker's content element
            marker.content.addEventListener('mouseover', () => {
                // Make the pin larger on hover
                pinBackground.scale = 1.5;

                // Set the content for the infoWindow and open it
                infoWindow.setContent(`
                <div style="font-family: Arial, sans-serif; font-size: 14px;">
                    <strong>${pet.name || 'Pet'}</strong><br>
                    Status: ${pet.post_type}
                </div>
            `);
                infoWindow.open(map, marker);
            });

            // 3. Add a 'mouseout' event listener to reset the style
            marker.content.addEventListener('mouseout', () => {
                // Reset the pin's scale
                pinBackground.scale = 1;

                // Close the infoWindow
                infoWindow.close();
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