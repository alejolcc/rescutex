defmodule Rescutex.Jobs.EmbeddingJob do
  @moduledoc """
  Oban worker to calculate embeddings for pets.
  """
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  alias Rescutex.AI
  alias Rescutex.Jobs.SimilarPetJob

  use Oban.Worker, max_attempts: 3, queue: :default

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"pet_id" => pet_id}}) do
    with %Pet{} = pet <- Pets.get_pet!(pet_id),
         {:ok, pet} <- AI.calculate_embedding(pet) do
      Oban.insert(Oban, SimilarPetJob.new(%{pet_id: pet.id}))
      Logger.info("Embedding calculated for pet #{pet.id}")
    end
  end
end
