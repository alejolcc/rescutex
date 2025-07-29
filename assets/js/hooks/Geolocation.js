const Geolocation = {
    mounted() {
        this.initMap()
    },

    async initMap() {
        console.log("initMap")
        const position = { lat: -32.9559518, lng: -60.660833 };
        const { Map } = await google.maps.importLibrary("maps");
        const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");

        // The map, centered at Uluru
        this.map = new Map(document.getElementById("map"), {
            zoom: 12,
            center: position,
            mapId: "DEMO_MAP_ID",
        });

        this.geocoder = new google.maps.Geocoder();
        this.marker = new AdvancedMarkerElement({});

        google.maps.event.trigger(this.map, "resize");

        this.map.addListener("click", (e) => {
            this.geocode({ location: e.latLng });
        });

        return this.map
    },

    geocode(request) {
        this.geocoder
            .geocode(request)
            .then((result) => {
                const { results } = result;
                const location = results[0].geometry.location;

                this.map.setCenter(location);
                this.marker.position = location;
                this.marker.map = this.map;
                let json = JSON.stringify(result, null, 2);
                console.log(results[0]);
                this.pushEventTo("#pet-form", "geocoding", { results: results[0] })
                return results;
            })
            .catch((e) => {
                console.error("Geocode was not successful for the following reason: " + e);
            });
    }

}

export default Geolocation;