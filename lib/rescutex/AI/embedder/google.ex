defmodule Rescutex.AI.Embedder.Google do
  @behaviour Rescutex.AI.Embedder
  alias Rescutex.AI.Google.Client

  @impl true
  def create_embedding(binary) do
    Client.create_embedding(binary)
  end
end
