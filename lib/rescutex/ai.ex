defmodule Rescutex.AI do
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet

  require Logger

  # TODO: Call batch embeddings
  def calculate_embedding(pets) when is_list(pets) do
    Enum.each(pets, fn pet -> calculate_embedding(pet) end)
  end

  def calculate_embedding(%Pet{} = pet) do
    with {:ok, embeddings} <- Rescutex.AI.Google.Client.create_embedding(file_path(pet)) do
      Pets.update_pet(pet, %{embedding: embeddings})
      Logger.info("Embedding calculated for pet #{pet.id}")
    else
      _ -> Logger.error("Error calculating embedding for pet #{pet.id}")
    end
  end

  defp file_path(pet) do
    Path.join([:code.priv_dir(:rescutex), "static", "uploads", Path.basename(pet.pictures)])
  end
end
