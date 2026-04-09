defmodule Rescutex.Jobs.SearchJob do
  @moduledoc """
  Oban worker to perform pet searches based on uploaded images.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Rescutex.Pets
  alias Rescutex.Pets.PetSearch
  alias Rescutex.AI

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"search_params" => search_params}}) do
    topic = Application.fetch_env!(:rescutex, :topic)

    # Base64 decode image data back to binary
    search_params =
      case Map.get(search_params, "image_data") do
        encoded when is_binary(encoded) ->
          case Base.decode64(encoded) do
            {:ok, decoded} -> Map.put(search_params, "image_data", decoded)
            _ -> search_params
          end

        _ ->
          search_params
      end

    changeset = PetSearch.changeset(%PetSearch{}, search_params)

    with {:ok, search_struct} <- Ecto.Changeset.apply_action(changeset, :search),
         {:ok, search_with_embedding} <- AI.calculate_embedding(search_struct) do
      results = Pets.search_pets(search_with_embedding)

      Pets.broadcast(topic, {:search_results, results})
      :ok
    else
      {:error, reason} ->
        Pets.broadcast(topic, {:search_error, inspect(reason)})
        {:error, reason}
    end
  end
end
