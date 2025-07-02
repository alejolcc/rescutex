defmodule Rescutex.AI.EmbeddingJob do
  @moduledoc """
  Oban worker to calculate embeddings for pets.
  """
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet

  use Oban.Worker, max_attempts: 3, queue: :default

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"pet_id" => pet_id}}) do
    with %Pet{} = pet <- Pets.get_pet!(pet_id),
         {:ok, embeddings} <- Rescutex.AI.Google.Client.create_embedding(file_path(pet)) do
      Pets.update_pet(pet, %{embedding: embeddings})
      Logger.info("Embedding calculated for pet #{pet.id}")
    else
      _ -> Logger.error("Error calculating embedding for pet #{pet_id}")
    end
  end

  # TODO: Of course we need to store the files in S3 or GS
  defp file_path(pet) do
    Path.join([:code.priv_dir(:rescutex), "static", "uploads", Path.basename(pet.pictures)])
  end
end
