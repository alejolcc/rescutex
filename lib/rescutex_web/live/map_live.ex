defmodule RescutexWeb.MapLive do
  use RescutexWeb, :live_view

  alias Rescutex.Pets

  @impl true
  def mount(_params, _session, socket) do
    pets = Pets.get_lost_pets()

    socket =
      socket
      |> assign(:api_key, Application.get_env(:rescutex, :google_api_key))
      |> assign(pets: pets, page_title: "Mapa de mascotas perdidas")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Mapa de mascotas perdidas
    </.header>
    <div class="h-[80vh] w-full" id="map" phx-hook="BigMap"></div>
    """
  end

  @impl true
  def handle_event("update-markers", _, socket) do
    pets = Pets.get_lost_pets()
    {:noreply, push_event(socket, "update-markers", %{pets: pets})}
  end
end
