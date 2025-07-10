defmodule RescutexWeb.PetLive.Show do
  use RescutexWeb, :live_view
  import RescutexWeb.CustomComponents

  alias Rescutex.Pets

  @impl true
  def mount(%{"id" => pet_id} = _params, _session, socket) do
    pet = Pets.get_pet!(pet_id)

    socket =
      socket
      |> assign(:api_key, Application.get_env(:rescutex, :google_api_key))
      |> assign(:pet, pet)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-100">
      <div class="container mx-auto my-5 p-5">
        <div class="md:flex no-wrap md:-mx-2 ">
          <!-- Left Side -->
          <div class="w-full md:w-3/12 md:mx-2">
            <!-- Profile Card -->
            <div class="image overflow-hidden">
              <img class="h-auto w-full mx-auto" src={"/uploads/#{@pet.pictures}"} alt="" />
            </div>
            <!-- End of profile card -->
            <div class="my-4"></div>
            <!-- Friends card -->
            <div class="bg-white p-3 hover:shadow">
              <div class="flex items-center space-x-3 font-semibold text-gray-900 text-xl leading-8">
                <span class="text-black">
                  <svg
                    class="h-5 fill-current"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M10.5 3.75a6.75 6.75 0 100 13.5 6.75 6.75 0 000-13.5zM2.25 10.5a8.25 8.25 0 1114.59 5.28l4.69 4.69a.75.75 0 11-1.06 1.06l-4.69-4.69A8.25 8.25 0 012.25 10.5z"
                    />
                  </svg>
                </span>
                <span>Similar Pets</span>
              </div>
              <div class="grid grid-cols-3">
                <div :for={similar_pet <- get_similars(@pet, 6)}>
                  <.link navigate={~p"/pets/#{similar_pet.id}"}>
                    <.rounded_img_with_name
                      name={similar_pet.name}
                      src={"/uploads/#{similar_pet.pictures}"}
                    />
                  </.link>
                </div>
              </div>
            </div>
            <!-- End of friends card -->
          </div>
          <!-- Right Side -->
          <div class="w-full md:w-9/12 mx-2 h-64">
            <!-- About Section -->
            <div class="bg-white p-3 shadow-sm rounded-sm">
              <div class="text-gray-700">
                <div class="grid md:grid-cols-3 text-sm">
                  <!-- 1st col -->
                  <div>
                    <div class="grid grid-cols-2">
                      <div class="px-4 py-2 font-semibold">Name</div>
                      <div class="px-4 py-2">{@pet.name}</div>
                    </div>
                    <div class="grid grid-cols-2">
                      <div class="px-4 py-2 font-semibold">Kind</div>
                      <div class="px-4 py-2">{@pet.kind}</div>
                    </div>
                    <div class="grid grid-cols-2">
                      <div class="px-4 py-2 font-semibold">Gender</div>
                      <div class="px-4 py-2">{@pet.gender}</div>
                    </div>
                    <div class="grid grid-cols-2">
                      <div class="px-4 py-2 font-semibold">Age</div>
                      <div class="px-4 py-2">{@pet.age}</div>
                    </div>
                    <div class="grid grid-cols-2">
                      <div class="px-4 py-2 font-semibold">Race</div>
                      <div class="px-4 py-2">{@pet.race}</div>
                    </div>
                    <div class="grid grid-cols-2">
                      <div class="px-4 py-2 font-semibold">Post Type</div>
                      <div class="px-4 py-2">{@pet.post_type}</div>
                    </div>
                  </div>
                  <!-- 2nd col -->
                  <div>
                    <div class="justify-items-start grid grid-cols-2">
                      <.pet_tag tag="pelo largo" />
                      <.pet_tag tag="blanco" />
                      <.pet_tag tag="negro" />
                      <.pet_tag tag="grande" />
                    </div>
                  </div>
                  <!-- 3rd col -->
                  <div>
                    <.embeded_map
                      api_key={@api_key}
                      latitud={@pet.lat}
                      longitud={@pet.long}
                      width={350}
                      height={300}
                    />
                  </div>
                </div>
              </div>
            </div>
            <!-- End of about section -->
            <div class="my-4"></div>
            <!-- Experience and education -->
            <div class="bg-white p-3 shadow-sm rounded-sm">
              <div class="grid ">
                <div>
                  <div class="flex items-center font-semibold text-gray-900 leading-8 mb-3">
                    <span clas="text-green-500">
                      <svg
                        class="h-5"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                        />
                      </svg>
                    </span>
                    <span class="tracking-wide">Details</span>
                  </div>
                  <div class=" space-y-2">
                    <span class="tracking-wide text-xl">
                      {@pet.details}
                    </span>
                  </div>
                </div>
              </div>
              <!-- End of Experience and education grid -->
            </div>
            <!-- End of profile tab -->
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:pet, Pets.get_pet!(id))}
  end

  defp page_title(:show), do: "Show Pet"
  defp page_title(:edit), do: "Edit Pet"

  defp get_similars(pet, n) do
    Pets.get_similar_pets(pet, limit: n)
  end
end
