defmodule Rescutex.AI do
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  alias Rescutex.AI.Google.Client

  require Logger

  @doc """
  Calculates embeddings for a list of pets.
  """
  def calculate_embedding(pets) when is_list(pets) do
    # Note: For production, consider Task.async_stream here for concurrency
    Enum.each(pets, fn pet -> calculate_embedding(pet) end)
  end

  @doc """
  Orchestrates the pipeline: Read Image -> Remove Background (optional) -> Embed -> Update DB.
  """
  def calculate_embedding(%Pet{} = pet) do
    with {:ok, original_binary} <- read_pet_image(pet),
         # Determine which image to use (Processed vs Original)
         {:ok, image_to_embed} <- process_image_for_embedding(pet, original_binary),
         # Generate Embedding
         {:ok, embeddings} <- Client.create_embedding(image_to_embed) do
      Pets.update_pet(pet, %{embedding: embeddings})
    else
      {:error, reason} ->
        Logger.error("Failed to calculate embedding for Pet #{pet.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ==========================================
  # Pipeline Steps
  # ==========================================

  defp process_image_for_embedding(pet, original_binary) do
    # Try to remove background
    case Client.remove_background(original_binary) do
      {:ok, response_body} ->
        # Success: Decode the new image
        case decode_gemini_image(response_body) do
          {:ok, processed_binary} ->
            # Write to disk only if needed
            save_debug_image(pet, processed_binary)
            {:ok, processed_binary}

          _ ->
            Logger.warning("Background removed, but failed to decode image. Using original.")
            {:ok, original_binary}
        end

      {:error, reason} ->
        # Failure: Fallback to original image as requested
        Logger.warning(
          "Remove background failed for Pet #{pet.id} (#{inspect(reason)}). Using original image."
        )

        {:ok, original_binary}
    end
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

  # Extracts the raw binary from the complex Gemini JSON structure
  defp decode_gemini_image(body) do
    try do
      base64_data =
        get_in(body, [
          "candidates",
          Access.at(0),
          "content",
          "parts",
          Access.at(0),
          "inlineData",
          "data"
        ])

      if base64_data do
        {:ok, Base.decode64!(base64_data)}
      else
        {:error, :no_image_data_found}
      end
    rescue
      e -> {:error, e}
    end
  end

  # Keeps the debug file writing logic, but prevents it from blocking the main flow
  defp save_debug_image(pet, binary) do
    # Naming convention: original_name_no_bg.jpg
    filename = "#{Path.basename(pet.pictures, Path.extname(pet.pictures))}_no_bg.jpg"
    path = Path.join("/tmp", filename)

    case File.write(path, binary) do
      :ok -> Logger.debug("Debug image saved: #{path}")
      {:error, reason} -> Logger.warning("Failed to save debug image: #{inspect(reason)}")
    end
  end

  defp local_file_path(pet) do
    # Assuming the logic from your previous code: the source images are in /tmp
    Path.join(["/tmp", Path.basename(pet.pictures)])
  end
end
