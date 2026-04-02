defmodule Rescutex.AI.Embedder.Noop do
  @behaviour Rescutex.AI.Embedder

  @impl true
  def create_embedding(_binary) do
    # Returns a dummy 1408-dimensional vector (Google Multimodal Embedding)
    {:ok, for(_ <- 1..1408, do: 0.0)}
  end
end
