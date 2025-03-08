defmodule Rescutex.AI.Worker do
  alias Rescutex.Pets
  alias Rescutex.Pets.Pet

  use GenServer

  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def calculate_embedding(pets) when is_list(pets) do
    Enum.each(pets, fn pet -> calculate_embedding(pet) end)
  end

  def calculate_embedding(%Pet{} = pet) do
    GenServer.cast(__MODULE__, {:calculate_embedding, pet})
  end

  def handle_cast({:calculate_embedding, %Pet{} = pet}, state) do
    work(pet)
    {:noreply, state}
  end

  def handle_call({:calculate_embedding, %Pet{} = pet}, _from, state) do
    reply = work(pet)
    {:reply, reply, state}
  end

  defp work(pet) do
    path = file_path(pet)

    with {:ok, embeddings} <- Rescutex.AI.Google.Client.create_embedding(path) do
      Pets.update_pet(pet, %{embedding: embeddings})
      Logger.info("Embedding calculated for pet #{pet.id}")
    end
  end

  # TODO: Of course we need to store the files in S3 or GS
  defp file_path(pet) do
    Path.join([:code.priv_dir(:rescutex), "static", "uploads", Path.basename(pet.pictures)])
  end
end
