defmodule Rescutex.CloudStorage.Adapters.AdapterBehaviour do
  @moduledoc """
  Defines the behaviour for a cloud storage adapter.
  """

  @callback upload(
              file_path_or_binary :: binary(),
              location :: String.t(),
              options :: Keyword.t()
            ) ::
              {:ok, any()} | {:error, any()}

  @doc """
  Downloads a file from the given location in the cloud.
  Should return the file's content as a binary on success.
  """
  @callback download(location :: String.t(), options :: Keyword.t()) ::
              {:ok, binary()} | {:error, any()}

  @callback list_objects() ::
              {:ok, {binary()}} | {:error, any()}
end
