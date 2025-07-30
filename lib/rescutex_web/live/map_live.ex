defmodule RescutexWeb.MapLive do
  use RescutexWeb, :live_view

  alias Rescutex.Pets
  alias Rescutex.Pets.Pet

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
      <%!-- TODO: Move this to root.html --%>
      <div class="h-[80vh] w-full" phx-update="ignore" id="pets_map" phx-hook="PetsMap"></div>
    </div>
    """
  end

  @impl true
  def handle_event("update-markers", _, socket) do
    pets_locations = Pets.get_lost_pets() |> Enum.map(&get_locations/1)
    {:noreply, push_event(socket, "update-markers", %{pets: pets_locations})}
  end

  defp get_locations(%Pet{location: %{coordinates: {long, lat}}}) do
    %{long: long, lat: lat}
  end
end
