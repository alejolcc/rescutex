defmodule Rescutex.AI.Processor.Noop do
  @behaviour Rescutex.AI.Processor

  @impl true
  def remove_background(binary) do
    {:ok, binary}
  end
end
