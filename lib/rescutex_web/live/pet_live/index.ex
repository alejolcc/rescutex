defmodule RescutexWeb.PetLive.Index do
  use RescutexWeb, :live_view

  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  alias Rescutex.Jobs.EmbeddingJob

  import RescutexWeb.CustomComponents

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:api_key, Application.get_env(:rescutex, :google_api_key))
      |> stream_configure(:pets, dom_id: &"pet-#{&1.id}")
      |> stream(:pets, Pets.list_pets())
      |> assign(:tab_index, 0)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- TODO: Move this to root.html --%>
      <script
        src={"https://maps.googleapis.com/maps/api/js?key=#{@api_key}&loading=async&libraries=maps,marker&v=beta"}
        defer
      >
      </script>

      <div class="-mx-4 overflow-x-auto px-4 sm:mx-0 sm:px-0">
        <div class="inline-block min-w-full">
          <.tab_list id="index-search-tabs" selected={@tab_index}>
            <:tab id="all_pets" title="All Pets"></:tab>
            <:tab id="lost" title="Lost"></:tab>
            <:tab id="found" title="Found"></:tab>
            <:tab id="adoption" title="Adoption"></:tab>
            <:tab id="transit" title="Transit"></:tab>
          </.tab_list>
        </div>
      </div>

      <div class="relative items-center justify-center">
        <div class="grid lg:grid-cols-4 gap-4 sm:grid-cols-1">
          <div :if={@current_user} id="new_pet_button" phx-update="ignore">
            <.link navigate={~p"/pets/new"}>
              <.pet_card_button />
            </.link>
          </div>
          <div id="pets" phx-update="stream" class="contents">
            <div :for={{dom_id, pet} <- @streams.pets} id={dom_id}>
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
        </div>
      </div>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="pet-modal" show on_cancel={JS.navigate(~p"/pets")}>
      <.live_component
        module={RescutexWeb.PetLive.FormComponent}
        user={@current_user}
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
  # TODO: When the user clik on new pet take in mind the tab index to set the proper post type
  def handle_event("tab_clicked", %{"index" => tab_index}, socket) do
    filter =
      case tab_index do
        1 -> :lost
        2 -> :found
        3 -> :transit
        4 -> :adoption
        _ -> :none
      end

    socket =
      socket
      |> assign(:tab_index, tab_index)
      |> assign_pets(filter)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pet = Pets.get_pet!(id)
    {:ok, _} = Pets.delete_pet(pet)

    {:noreply, stream_delete(socket, :pets, pet)}
  end

  defp assign_pets(socket, :lost) do
    socket
    |> stream(:pets, Pets.list_pets(filters: [post_type: :lost]), reset: true)
  end

  defp assign_pets(socket, :found) do
    socket
    |> stream(:pets, Pets.list_pets(filters: [post_type: :found]), reset: true)
  end

  defp assign_pets(socket, :transit) do
    socket
    |> stream(:pets, Pets.list_pets(filters: [post_type: :transit]), reset: true)
  end

  defp assign_pets(socket, :adoption) do
    socket
    |> stream(:pets, Pets.list_pets(filters: [post_type: :adoption]), reset: true)
  end

  defp assign_pets(socket, :none) do
    socket
    |> stream(:pets, Pets.list_pets(), reset: true)
  end
end
