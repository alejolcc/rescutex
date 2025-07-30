const PetsMap = {
    mounted() {
        this.initMap();
    },

    async initMap() {
        const position = { lat: -32.9559518, lng: -60.660833 };
        const { Map } = await google.maps.importLibrary("maps");
        const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");
        const { MarkerClusterer } = await google.maps.importLibrary("marker");

        const map = new Map(this.el, {
            zoom: 12,
            center: position,
            mapId: "PETS_MAP_ID",
        });

        this.handleEvent("update-markers", ({ pets }) => {
            this.addMarkers(map, pets, AdvancedMarkerElement, MarkerClusterer);
        });

        this.pushEvent("update-markers");
    },

    addMarkers(map, pets, AdvancedMarkerElement, MarkerClusterer) {
        const markers = pets.map(pet_location => {
            return new AdvancedMarkerElement({
                position: { lat: pet_location.lat, lng: pet_location.long }
            });

        });

        const markerCluster = new markerClusterer.MarkerClusterer({ markers, map });
    }
};

export default PetsMap;