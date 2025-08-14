defmodule Rescutex.CloudStorage do
  @moduledoc """
  Module responsible for storing and retrieving files from the storage.

  TODO: When the postgres DB comes into play, we will need to store the file metadata in the DB.
  And map the id of the file to the file in the storage.
  """

  def upload(file_path_or_binary, key, opts \\ []) do
    adapter().upload(file_path_or_binary, key, opts)
  end

  def download(key, opts \\ []) do
    adapter().download(key, opts)
  end

  def list_objects(key, opts \\ []) do
    adapter().download(key, opts)
  end

  defp adapter do
    Application.get_env(:rescutex, Rescutex.CloudStorage)[:storage_adapter]
  end
end
