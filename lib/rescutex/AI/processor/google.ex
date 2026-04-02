defmodule Rescutex.AI.Processor.Google do
  @behaviour Rescutex.AI.Processor
  alias Rescutex.AI.Google.Client

  @impl true
  def remove_background(binary) do
    Client.remove_background(binary)
  end
end
