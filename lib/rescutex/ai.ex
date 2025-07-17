defmodule Rescutex.AI do
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet

  require Logger

  # TODO: Call batch embeddings
  def calculate_embedding(pets) when is_list(pets) do
    Enum.each(pets, fn pet -> calculate_embedding(pet) end)
  end

  # TODO: In case the remove background fail for something, we need to use the original image for embeeding
  def calculate_embedding(%Pet{} = pet) do
    with {:ok, tmp_file} <- remove_background(pet),
         {:ok, embeddings} <- Rescutex.AI.Google.Client.create_embedding(tmp_file) do
      Pets.update_pet(pet, %{embedding: embeddings})
    end
  end

  def remove_background(%Pet{} = pet) do
    with {:ok, body} <- Rescutex.AI.Google.Client.remove_background(file_path(pet)) do
      tmp_file = Path.join(["/tmp", Path.basename(pet.pictures) <> ".png"])

      img =
        body
        |> Map.get("candidates")
        |> hd()
        |> Map.get("content")
        |> Map.get("parts")
        |> hd()
        |> Map.get("inlineData")
        |> Map.get("data")
        |> :base64.decode()

      File.write!(tmp_file, img)

      {:ok, tmp_file}
    end
  end

  defp file_path(pet) do
    Path.join([:code.priv_dir(:rescutex), "static", "uploads", Path.basename(pet.pictures)])
  end
end
