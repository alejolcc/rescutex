defmodule Rescutex.AI.Processor do
  @moduledoc """
  Behaviour for image processing (e.g. background removal).
  """
  @callback remove_background(binary()) :: {:ok, binary()} | {:error, any()}
end
