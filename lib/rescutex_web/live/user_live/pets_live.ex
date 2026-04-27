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
      <div :for={pet <- @pets} id={"pet-#{pet.id}"}>
        <.pet_card
          src={pet.pictures}
          name={pet.name}
          text={pet.details}
          id={pet.id}
          gender={pet.gender}
          is_owner={true}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pet = Pets.get_pet!(id)
    {:ok, _} = Pets.delete_pet(pet)

    {:noreply,
     socket
     |> put_flash(:info, "Pet deleted successfully")
     |> assign(:pets, Enum.filter(socket.assigns.pets, &(&1.id != pet.id)))}
  end
end
