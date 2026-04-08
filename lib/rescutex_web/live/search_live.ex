defmodule RescutexWeb.SearchLive do
  use RescutexWeb, :live_view

  alias Rescutex.Pets
  alias Rescutex.Pets.PetSearch
  alias Rescutex.AI

  import RescutexWeb.CustomComponents

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:api_key, Application.get_env(:rescutex, :google_api_key))
      |> assign(:similar_pets, [])
      |> assign(:searching, false)
      |> assign(:location, nil)
      |> allow_upload(:photo,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 10_000_000
      )
      |> assign_form(Pets.PetSearch.changeset(%PetSearch{}, %{}))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <.header>
        Search by Photo
        <:subtitle>Upload a photo of a pet to find similar ones in our database.</:subtitle>
      </.header>

      <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-8">
        <div>
          <.simple_form
            for={@form}
            id="search-form"
            phx-change="validate"
            phx-submit="search"
          >
            <div class="space-y-4">
              <label class="block text-sm font-semibold leading-6 text-zinc-800">
                Location
              </label>
              <div class="w-full h-64 rounded-lg overflow-hidden border border-zinc-300">
                <div id="map" phx-update="ignore" phx-hook="Geolocation" class="w-full h-full"></div>
              </div>
              <p :if={is_nil(@location)} class="text-xs text-red-600 mt-1">
                Please select a location on the map.
              </p>
            </div>

            <.input field={@form[:kind]} type="select" label="Kind" options={[{"Dog", "dog"}, {"Cat", "cat"}]} prompt="Select pet type" />
            <.input field={@form[:distance_in_meters]} type="number" label="Search Radius (meters)" step="100" />

            <div class="space-y-2">
               <label class="block text-sm font-semibold leading-6 text-zinc-800">
                Photo
              </label>
              <div
                class="mt-2 flex justify-center rounded-lg border border-dashed border-zinc-900/25 px-6 py-10"
                phx-drop-target={@uploads.photo.ref}
              >
                <div class="text-center">
                  <div class="mt-4 flex text-sm leading-6 text-zinc-600">
                    <label class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
                      <span>Upload a file</span>
                      <.live_file_input upload={@uploads.photo} class="sr-only" />
                    </label>
                    <p class="pl-1">or drag and drop</p>
                  </div>
                  <p class="text-xs leading-5 text-zinc-600">PNG, JPG, GIF up to 10MB</p>
                </div>
              </div>

              <div :for={entry <- @uploads.photo.entries} class="mt-4">
                <.live_img_preview entry={entry} class="w-32 h-32 object-cover rounded-lg" />
                <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-sm text-red-600 mt-2">
                  Cancel
                </button>
                <.error :for={err <- upload_errors(@uploads.photo, entry)}>{Phoenix.Naming.humanize(err)}</.error>
              </div>
            </div>

            <:actions>
              <.button phx-disable-with="Searching..." disabled={@searching or is_nil(@location) or Enum.empty?(@uploads.photo.entries)}>
                <%= if @searching do %>
                  Searching...
                <% else %>
                  Find Similar Pets
                <% end %>
              </.button>
            </:actions>
          </.simple_form>
        </div>

        <div>
          <h2 class="text-lg font-semibold text-zinc-800 mb-4">Results</h2>
          <div :if={Enum.empty?(@similar_pets) and not @searching} class="text-zinc-500 italic">
            Upload a photo and select a location to see results.
          </div>

          <div :if={@searching} class="flex items-center space-x-2 text-indigo-600">
             <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            <span>Processing image and searching...</span>
          </div>

          <div id="results" class="grid grid-cols-1 gap-4">
            <div :for={pet <- @similar_pets} id={"pet-#{pet.id}"}>
              <.link navigate={~p"/pets/#{pet.id}"}>
                <.pet_card
                  src={pet.pictures}
                  name={pet.name}
                  text={pet.details}
                  id={pet.id}
                  gender={pet.gender}
                />
              </.link>
            </div>
          </div>
          <div :if={not Enum.empty?(@similar_pets) and not @searching and length(@similar_pets) == 0} class="text-zinc-500">
            No similar pets found within the selected criteria.
          </div>
        </div>
      </div>
    </div>

    <script
      src={"https://maps.googleapis.com/maps/api/js?key=#{@api_key}&loading=async&libraries=maps,marker&v=beta"}
      defer
    >
    </script>
    """
  end

  @impl true
  def handle_event("validate", %{"pet_search" => params}, socket) do
    changeset =
      %PetSearch{}
      |> PetSearch.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  @impl true
  def handle_event("geocoding", %{"results" => results}, socket) do
    %{"lat" => lat, "lng" => long} = results["geometry"]["location"]
    # Create Geo struct. Assuming SRID 4326
    location = %Geo.Point{coordinates: {long, lat}, srid: 4326}

    {:noreply, assign(socket, :location, location)}
  end

  @impl true
  def handle_event("search", %{"pet_search" => params}, socket) do
    if is_nil(socket.assigns.location) do
       {:noreply, put_flash(socket, :error, "Please select a location on the map")}
    else
      # Start searching state
      socket = assign(socket, :searching, true)

      # Consume uploaded file
      image_data =
        consume_uploaded_entries(socket, :photo, fn %{path: path}, _entry ->
          {:ok, File.read!(path)}
        end)
        |> List.first()

      if is_nil(image_data) do
        {:noreply, assign(socket, :searching, false) |> put_flash(:error, "Please upload a photo")}
      else
        # Prepare search struct
        search_struct = %PetSearch{
          kind: String.to_existing_atom(params["kind"]),
          distance_in_meters: String.to_integer(params["distance_in_meters"]),
          location: socket.assigns.location,
          image_data: image_data
        }

        # AI processing (async in a task to avoid blocking the LV process if it's heavy,
        # but here we'll do it synchronously for simplicity unless it's too slow)
        case AI.calculate_embedding(search_struct) do
          {:ok, search_with_embedding} ->
            results = Pets.search_pets(search_with_embedding)
            {:noreply,
             socket
             |> assign(:similar_pets, results)
             |> assign(:searching, false)}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:searching, false)
             |> put_flash(:error, "Failed to process image: #{inspect(reason)}")}
        end
      end
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
