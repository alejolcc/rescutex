defmodule RescutexWeb.UserLive.PetsLive do
  use RescutexWeb, :live_view

  alias Rescutex.Pets
  import RescutexWeb.CustomComponents

  @impl true
  def mount(_params, _session, socket) do
    pets = Pets.list_pets_for_user(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "My Pets")
     |> assign(:pets, pets)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="text-center">
      My Pets
    </.header>

    <div class="grid grid-cols-1 gap-4 p-4 justify-items-center">
      <.link :for={pet <- @pets} navigate={~p"/pets/#{pet.id}"}>
        <.pet_card src={pet.pictures} name={pet.name} text={pet.details} id={pet.id} />
      </.link>
    </div>
    """
  end
end
