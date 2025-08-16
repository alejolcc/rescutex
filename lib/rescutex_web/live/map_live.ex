defmodule RescutexWeb.MapLive do
  use RescutexWeb, :live_view

  alias Rescutex.Pets

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:api_key, Application.get_env(:rescutex, :google_api_key))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="h-[80vh] w-full" phx-update="ignore" id="pets_map" phx-hook="PetsMap"></div>
    </div>
    """
  end

  @impl true
  def handle_event("update-markers", _, socket) do
    pets_locations =
      Pets.list_pets()
      |> Enum.map(fn pet -> Map.take(pet, [:id, :location, :post_type, :pictures, :details]) end)
      |> Enum.map(&get_data/1)

    {:noreply, push_event(socket, "update-markers", %{pets: pets_locations})}
  end

  defp get_data(data) do
    image_url = build_image_url(data.pictures)
    %{location: %{coordinates: {long, lat}}} = data

    %{
      long: long,
      lat: lat,
      post_type: Atom.to_string(data.post_type),
      id: data.id,
      image_url: image_url,
      details: data.details
    }
  end

  # TODO: This function is spread in all the code
  defp build_image_url([src | _]) do
    # This is not a good practice
    impl_source = Application.get_env(:rescutex, Rescutex.CloudStorage)[:storage_adapter]

    case impl_source do
      Rescutex.CloudStorage.Adapters.S3 -> "http://rescutex-images.t3.storageapi.dev/#{src}"
      _ -> "/uploads/#{src}"
    end
  end
end
