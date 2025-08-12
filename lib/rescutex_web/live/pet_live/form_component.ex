defmodule RescutexWeb.PetLive.FormComponent do
  use RescutexWeb, :live_component

  alias Rescutex.Pets
  alias Rescutex.CloudStorage
  import RescutexWeb.CustomComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage pet records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="pet-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- TODO: create a map input component --%>
        <div class="w-96 h-96">
          <div id="map" phx-update="ignore" phx-hook="Geolocation" class="w-full h-full"></div>
        </div>
        <.error :for={msg <- @map_error}>{msg}</.error>

        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:age]} type="number" label="Age" />
        <.input field={@form[:race]} type="text" label="Race" />
        <.input field={@form[:gender]} type="text" label="Gender" />
        <.input field={@form[:details]} type="textarea" label="Details" />
        <.input field={@form[:kind]} type="select" label="Kind" options={@kind_select} />
        <.input field={@form[:post_type]} type="select" label="Post type" options={@post_type_select} />

        <.upload_component uploads={@uploads} />

        <:actions>
          <.button phx-disable-with="Saving...">Save Pet</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{pet: pet} = assigns, socket) do
    changeset = Pets.change_pet(pet)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"pet" => pet_params}, socket) do
    location = Map.get(socket.assigns, :location)
    img = socket.assigns.uploaded_files

    pet_params =
      pet_params
      |> Map.put("location", location)
      |> Map.put("pictures", img)

    changeset =
      socket.assigns.pet
      |> Pets.change_pet(pet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  # We don want to call the geocoding function each time that we validate the form
  # so we "cache" the result in the socket assigns outside of the form
  def handle_event("geocoding", %{"results" => results}, socket) do
    %{"lat" => lat, "lng" => long} = results["geometry"]["location"]

    socket =
      socket
      |> assign(:location, %{"lat" => lat, "long" => long})

    {:noreply, socket}
  end

  # When we try to save the form we get the "cached" lat and long from the socket assigns
  def handle_event("save", %{"pet" => pet_params}, socket) do
    # handle the uploaded files
    socket = handle_upload(socket)
    img = socket.assigns.uploaded_files

    location = Map.get(socket.assigns, :location, nil)

    pet_params =
      pet_params
      |> Map.put("location", location)
      |> Map.put("pictures", img)

    save_pet(socket, socket.assigns.action, pet_params)
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  # TODO: In case the picture is updated we need to create a new embedding otherwise we should not notifiy
  # defp save_pet(socket, :edit, pet_params) do
  #   case Pets.update_pet(socket.assigns.pet, pet_params) do
  #     {:ok, pet} ->
  #       notify_parent({:saved, pet})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Pet updated successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign_form(socket, changeset)}
  #   end
  # end

  defp save_pet(socket, :new, pet_params) do
    user = socket.assigns.user

    case Pets.create_pet(user, pet_params) do
      {:ok, pet} ->
        notify_parent({:saved, pet})

        {:noreply,
         socket
         |> put_flash(:info, "Pet created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    post_type_select = [
      {"Found", "found"},
      {"Lost", "lost"},
      {"Transit", "transit"},
      {"Adoption", "adoption"}
    ]

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:kind_select, [{"Cat", "cat"}, {"Dog", "dog"}])
    |> assign(:post_type_select, post_type_select)
    |> assign(:map_error, map_error(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp map_error(%Ecto.Changeset{errors: errors}) do
    if Keyword.has_key?(errors, :location) do
      ["Select the location"]
    else
      []
    end
  end

  defp handle_upload(socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        # First we copy the img to /tmp file to do some preprocesing before calculate the embedding
        dest = Path.join(["/tmp/pictures/", Path.basename(path)])
        File.cp!(path, dest)

        # After that we upload the original photo to the cloud
        CloudStorage.upload(path, "#{Path.basename(path)}.png")
        {:postpone, "#{Path.basename(path)}.png"}
      end)

    update(socket, :uploaded_files, fn _ -> uploaded_files end)
  end
end
