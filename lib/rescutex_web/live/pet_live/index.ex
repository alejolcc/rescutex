defmodule RescutexWeb.PetLive.Index do
  use RescutexWeb, :live_view

  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  alias Rescutex.AI.Worker

  import RescutexWeb.CustomComponents

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:api_key, Application.get_env(:rescutex, :google_api_key))
      |> stream(:pets, Pets.list_pets(), dom_id: &"pet-#{&1.id}")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <script
        src={"https://maps.googleapis.com/maps/api/js?key=#{@api_key}&loading=async&libraries=maps,marker&v=beta"}
        defer
      >
      </script>

      <div class="relative items-center justify-center">
        <div class="grid lg:grid-cols-4 gap-4 sm:grid-cols-1">
          <div>
            <.link navigate={~p"/pets/new"}>
              <.pet_card_button />
            </.link>
          </div>
          <div id="pets" phx-update="stream" class="contents">
            <div :for={{dom_id, pet} <- @streams.pets} id={dom_id}>
              <.link navigate={~p"/pets/#{pet.id}"}>
                <.pet_card src={pet.pictures} name={pet.name} text={pet.details} />
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="pet-modal" show on_cancel={JS.patch(~p"/pets")}>
      <.live_component
        module={RescutexWeb.PetLive.FormComponent}
        id={@pet.id || :new}
        title={@page_title}
        action={@live_action}
        pet={@pet}
        patch={~p"/pets"}
      />
    </.modal>
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pet")
    |> assign(:pet, Pets.get_pet!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pet")
    |> assign(:pet, %Pet{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Pets")
    |> assign(:pet, nil)
  end

  @impl true
  def handle_info({RescutexWeb.PetLive.FormComponent, {:saved, pet}}, socket) do
    Worker.calculate_embedding(pet)
    {:noreply, stream_insert(socket, :pets, pet)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pet = Pets.get_pet!(id)
    {:ok, _} = Pets.delete_pet(pet)

    {:noreply, stream_delete(socket, :pets, pet)}
  end
end
