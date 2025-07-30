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
            this.addMarkers(map, pets, AdvancedMarkerElement);
        });

        this.pushEvent("update-markers");
    },

    addMarkers(map, pets, AdvancedMarkerElement) {
        pets.forEach(pet_location => {
            new AdvancedMarkerElement({
                position: { lat: pet_location.lat, lng: pet_location.long },
                map: map,
            });
        });

    }
};

export default PetsMap;