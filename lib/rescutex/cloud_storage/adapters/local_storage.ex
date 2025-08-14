defmodule Rescutex.CloudStorage.Adapters.LocalStorage do
  @behaviour Rescutex.CloudStorage.Adapters.AdapterBehaviour

  @dest "/tmp/rescutex_storage"
  @doc """
  "Uploads" a file to the local storage.
  """
  @impl true
  def upload(file_path_or_binary, _dest, opts) do
    name = opts[:name] || Path.basename(file_path_or_binary)

    binary =
      if File.regular?(file_path_or_binary) do
        File.read!(file_path_or_binary)
      else
        file_path_or_binary
      end

    File.write(Path.join(@dest, name), binary)
  end

  @doc """
  Downloads an object from the local storage.
  """
  @impl true
  def download(name, _opts) do
    File.read(Path.join(@dest, name))
  end

  @impl true
  def list_objects() do
    File.ls(@dest)
  end
end
