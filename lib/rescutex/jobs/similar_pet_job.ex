defmodule Rescutex.Jobs.SimilarPetJob do
  @moduledoc """
  Oban Job to get similar pets
  """
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet

  use Oban.Worker, max_attempts: 3, queue: :default

  require Logger

  @threshold 0.65

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"pet_id" => pet_id}}) do
    with %Pet{} = pet <- Pets.get_pet!(pet_id) do
      Pets.get_similar_pets_within_distance(pet, @threshold)
      Logger.info("Embedding calculated for pet #{pet.id}")
    end
  end
end
