defmodule Rescutex.AI.Embedder do
  @moduledoc """
  Behaviour for image embedding generation.
  """
  @callback create_embedding(binary()) :: {:ok, [float()]} | {:error, any()}
end
