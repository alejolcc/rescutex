defmodule RescutexWeb.CustomComponents do
  @moduledoc """
  Components created by hand using tailwind components as a base.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :selected, :integer, default: 0

  slot :tab do
    attr :title, :string, required: true, doc: "Name of the tab"
    attr :id, :string, required: true
  end

  def tab_list(assigns) do
    ~H"""
    <div class="mx-auto mt-4 rounded">
      <!-- Tabs -->
      <ul id={@id} class="inline-flex w-full px-1 pt-2 ">
        <%= for {tab, i} <- Enum.with_index(@tab) do %>
          <li class={[
            "px-4 py-2 font-semibold text-gray-800 rounded-t",
            "#{@selected}" == "#{i}" && "border-b-4 border-blue-400"
          ]}>
            <button id={"#{tab.id}"} phx-click={show_tab(@id, i)}>{tab.title}</button>
          </li>
        <% end %>
      </ul>
      <!-- Tab Contents -->
      <%= for {tab, i} <- Enum.with_index(@tab) do %>
        <div id={"#{@id}-#{i}-content"} class={if "#{@selected}" != "#{i}", do: "hidden"} class="p-4">
          {render_slot(tab)}
        </div>
      <% end %>
    </div>
    """
  end

  defp show_tab(js \\ %JS{}, id, tab_index) do
    js
    |> JS.push("tab_clicked", value: %{id: id, index: tab_index})
  end

  def pet_card(assigns) do
    image_url = assigns.src |> build_image_url()

    assigns =
      assigns
      |> assign(:src, image_url)

    ~H"""
    <div class="m-4 shadow-md hover:shadow-lg hover:bg-gray-100 rounded-lg bg-white">
      <!-- Card Image -->
      <img src={"#{@src}"} alt="" class="object-cover w-96 h-96 overflow-hidden" />
      <!-- Card Content -->
      <div class="p-4">
        <h3 class="font-medium text-lg my-2 uppercase flex flex-row flex-nowrap items-center">
          {@name} &nbsp; {pet_gender(@gender)}
        </h3>
        <p class="text-justify">
          {@text}
        </p>
        <div class="mt-5">
          <a
            href={"/pets/#{@id}"}
            class="hover:bg-gray-700 rounded-full py-2 px-3 font-semibold hover:text-white bg-gray-400 text-gray-100"
          >
            More Info
          </a>
        </div>
      </div>
    </div>
    """
  end

  def pet_card_button(assigns) do
    ~H"""
    <div class="m-4 shadow-md hover:shadow-lg hover:bg-gray-100 rounded-lg bg-white">
      <!-- Card Image -->
      <img
        src="/images/perro.png"
        alt=""
        class="object-cover w-96 h-96 overflow-hidden  object-scale-down"
      />
      <!-- Card Content -->
      <div class="p-4">
        <h3 class="font-medium text-gray-600 text-lg my-2 uppercase">ADD PET</h3>
        <p class="text-justify">
          Start helping adding a pet to adopt, or report a missing pet
        </p>
        <div class="mt-5">
          <a
            href=""
            class="hover:bg-gray-700 rounded-full py-2 px-3 font-semibold hover:text-white bg-gray-400 text-gray-100"
          >
            More Info
          </a>
        </div>
      </div>
    </div>
    """
  end

  def embeded_map(assigns) do
    assigns =
      assigns
      |> assign(
        :map_url,
        "https://www.google.com/maps/embed/v1/place?key=#{assigns.api_key}&q=#{assigns.latitud},#{assigns.longitud}&zoom=13"
      )
      |> assign(:height, assigns.height)

    ~H"""
    <iframe
      width="100%"
      height={@height}
      style="border:0"
      loading="lazy"
      allowfullscreen
      referrerpolicy="strict-origin-when-cross-origin"
      src={@map_url}
    >
      <p>Your browser does not support iframes.</p>
    </iframe>
    """
  end

  def rounded_img_with_name(assigns) do
    image_url = assigns.src |> build_image_url()

    assigns =
      assigns
      |> assign(:src, image_url)

    ~H"""
    <div class="text-center my-2">
      <img class="h-16 w-16 rounded-full mx-auto" src={@src} alt="" />
      <a href="#" class="text-main-color">{@name}</a>
    </div>
    """
  end

  def upload_component(assigns) do
    ~H"""
    <div class="flex items-center justify-center p-12">
      <div class="mx-auto w-full max-w-[550px] bg-white">
        <!-- Form -->
        <%!-- <form class="py-6 px-9" id="upload-form" phx-submit="save" phx-change="validate"> --%>
        <div class="mb-6 pt-4">
          <label class="mb-5 block text-xl font-semibold text-[#07074D]">
            Upload File
          </label>

          <div class="mb-8">
            <input type="file" name="file" id="file" class="sr-only" />
            <label
              for="file"
              class="relative flex min-h-[200px] items-center justify-center rounded-md border border-dashed border-[#e0e0e0] p-12 text-center"
            >
              <div phx-drop-target={@uploads.avatar.ref}>
                <span class="mb-2 block text-xl font-semibold text-[#07074D]">
                  Drop files here
                  <section></section>
                </span>
                <span class="mb-2 block text-base font-medium text-[#6B7280]">
                  Or
                </span>
                <span class="inline-flex rounded border border-[#e0e0e0] py-2 px-7 text-base font-medium text-[#07074D]">
                  <label class="my-classes">
                    <.live_file_input upload={@uploads.avatar} />
                  </label>
                </span>
              </div>
            </label>
          </div>

          <%= for entry <- @uploads.avatar.entries do %>
            <article class="upload-entry">
              <figure>
                <.live_img_preview entry={entry} />
              </figure>

              <%!-- <progress value={entry.progress} max="100"><%= entry.progress %>%</progress> --%>

              <progress value={entry.progress} max="100">{entry.progress}%</progress>
              <div class="rounded-md bg-[#F5F7FB] py-4 px-8">
                <div class="flex items-center justify-between">
                  <span class="truncate pr-3 text-base font-medium text-[#07074D]">
                    {entry.client_name}
                  </span>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    aria-label="cancel"
                  >
                    &times;
                  </button>
                </div>
                <.progress_bar progress={entry.progress} />
              </div>

              <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
              <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                <p class="alert alert-danger">{error_to_string(err)}</p>
              <% end %>
            </article>
          <% end %>
        </div>

        <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
        <%= for err <- upload_errors(@uploads.avatar) do %>
          <p class="alert alert-danger">{error_to_string(err)}</p>
        <% end %>
        <%!-- </form> --%>
      </div>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp progress_bar(assigns) do
    ~H"""
    <div class="relative mt-5 h-[6px] w-full rounded-lg bg-[#E2E5EF]">
      <div class={"absolute left-0 right-0 h-full w-[#{@progress}%] rounded-lg bg-[#6A64F1]"}></div>
    </div>
    """
  end

  # TODO: We need to handle multiples images
  defp build_image_url([src | _]) do
    build_image_url(src)
  end

  defp build_image_url(src) do
    # This is not a good practice
    impl_source = Application.get_env(:rescutex, Rescutex.CloudStorage)[:storage_adapter]

    case impl_source do
      Rescutex.CloudStorage.Adapters.S3 -> "http://rescutex-images.t3.storageapi.dev/#{src}"
      _ -> "/uploads/#{src}"
    end
  end

  defp pet_gender(:male = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      fill="currentColor"
      class="bi bi-gender-male text-blue-500 "
      viewBox="0 0 16 16"
    >
      <path
        fill-rule="evenodd"
        d="M9.5 2a.5.5 0 0 1 0-1h5a.5.5 0 0 1 .5.5v5a.5.5 0 0 1-1 0V2.707L9.871 6.836a5 5 0 1 1-.707-.707L13.293 2zM6 6a4 4 0 1 0 0 8 4 4 0 0 0 0-8"
      />
    </svg>
    """
  end

  defp pet_gender(:female = assigns) do
    ~H"""
    <p>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        fill="currentColor"
        class="bi bi-gender-female text-pink-500"
        viewBox="0 0 16 16"
      >
        <path
          fill-rule="evenodd"
          d="M8 1a4 4 0 1 0 0 8 4 4 0 0 0 0-8M3 5a5 5 0 1 1 5.5 4.975V12h2a.5.5 0 0 1 0 1h-2v2.5a.5.5 0 0 1-1 0V13h-2a.5.5 0 0 1 0-1h2V9.975A5 5 0 0 1 3 5"
        />
      </svg>
    </p>
    """
  end

  defp pet_gender(assigns) do
    ~H"""
    """
  end
end
