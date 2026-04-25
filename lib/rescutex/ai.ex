defmodule Rescutex.AI do
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  alias Rescutex.Pets.PetSearch

  require Logger

  @doc """
  Calculates embeddings for a list of pets.
  """
  def calculate_embedding(pets) when is_list(pets) do
    # Note: For production, consider Task.async_stream here for concurrency
    Enum.each(pets, fn pet -> calculate_embedding(pet) end)
  end

  def calculate_embedding(%Pet{} = pet) do
    with {:ok, original_binary} <- read_pet_image(pet),
         # Determine which image to use (Processed vs Original)
         {:ok, image_to_embed} <- process_image_for_embedding(pet, original_binary),
         # Generate Embedding
         {:ok, embeddings} <- create_embedding(image_to_embed) do
      Pets.update_pet(pet, %{embedding: embeddings})
    else
      {:error, reason} ->
        Logger.error("Failed to calculate embedding for Pet #{pet.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def calculate_embedding(%PetSearch{} = search) do
    with {:ok, image_to_embed} <- process_image_for_embedding(search, search.image_data),
         {:ok, embeddings} <- create_embedding(image_to_embed) do
      {:ok, %PetSearch{search | embedding: embeddings}}
    else
      {:error, reason} ->
        Logger.error("Failed to calculate embedding for PetSearch: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ==========================================
  # Pipeline Steps
  # = ::::::::::::::::::::::::::::::::::::::::

  defp process_image_for_embedding(%Pet{} = pet, original_binary) do
    do_process_image(
      original_binary,
      fn processed_binary -> save_debug_image(pet, processed_binary) end,
      "Pet #{pet.id}"
    )
  end

  defp process_image_for_embedding(%PetSearch{}, original_binary) do
    do_process_image(original_binary, fn _ -> :ok end, "PetSearch")
  end

  defp do_process_image(original_binary, on_success_fn, log_context) do
    adapter = processor_adapter()

    # Try to process the image (e.g. remove background)
    case adapter.remove_background(original_binary) do
      {:ok, processed_binary} ->
        # Write to disk only if needed
        on_success_fn.(processed_binary)
        {:ok, processed_binary}

      {:error, reason} ->
        # Failure: Fallback to original image as requested
        Logger.warning(
          "Image processing failed for #{log_context} (#{inspect(reason)}). Using original image."
        )

        {:ok, original_binary}
    end
  end

  defp create_embedding(binary) do
    embedder_adapter().create_embedding(binary)
  end

  defp read_pet_image(pet) do
    path = local_file_path(pet)

    case File.read(path) do
      {:ok, binary} -> {:ok, binary}
      {:error, reason} -> {:error, "Could not read source file at #{path}: #{reason}"}
    end
  end

  # ==========================================
  # Helpers
  # ==========================================

  defp processor_adapter do
    Application.get_env(:rescutex, :ai)[:processor_adapter]
  end

  defp embedder_adapter do
    Application.get_env(:rescutex, :ai)[:embedder_adapter]
  end

  # Keeps the debug file writing logic, but prevents it from blocking the main flow
  defp save_debug_image(pet, binary) do
    # Naming convention: original_name_no_bg.jpg
    [first_picture | _] = pet.pictures
    filename = "#{Path.basename(first_picture, Path.extname(first_picture))}_no_bg.jpg"
    path = Path.join("/tmp", filename)

    case File.write(path, binary) do
      :ok -> Logger.debug("Debug image saved: #{path}")
      {:error, reason} -> Logger.warning("Failed to save debug image: #{inspect(reason)}")
    end
  end

  defp local_file_path(pet) do
    # Assuming the logic from your previous code: the source images are in /tmp
    [first_picture | _] = pet.pictures
    Path.join(["/tmp", Path.basename(first_picture)])
  end
end
