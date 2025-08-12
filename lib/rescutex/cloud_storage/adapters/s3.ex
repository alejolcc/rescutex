defmodule Rescutex.CloudStorage.Adapters.S3 do
  @behaviour Rescutex.CloudStorage.Adapters.AdapterBehaviour

  @moduledoc """
  An adapter for `Rescutex.CloudStorage` that uses AWS S3 via the `ex_aws` library.

  This adapter requires the bucket to be configured. For example, in your `config/config.exs`:

      config :rescutex, #{inspect(__MODULE__)},
        bucket: "your-s3-bucket-name"

  It also relies on `ex_aws` being configured with your AWS credentials.
  """

  @doc """
  Uploads a file from a given `file_path or binary` to S3.

  ## Options

  The `options` keyword list is passed directly to `ExAws.S3.upload/4`.
  You can use it to set things like `acl`, `content_type`, etc.

  See `ExAws.S3.upload/4` documentation for more details.
  """
  @impl Rescutex.CloudStorage.Adapters.AdapterBehaviour
  def upload(file_path_or_binary, key, options \\ []) do
    # We tell the browser to cache this image for 1 year (a common practice for static assets)
    # "public" means it can be cached by intermediate proxies, not just the user's browser.
    cache_headers = %{"Cache-Control" => "public, max-age=31536000"}

    # Pass the headers as options
    common_opts = [meta: cache_headers, cache_control: "public, max-age=31536000"]

    acl = Keyword.get(options, :acl, :public_read)
    options = Keyword.put(common_opts, :acl, acl)

    binary =
      if File.regular?(file_path_or_binary) do
        File.read!(file_path_or_binary)
      else
        file_path_or_binary
      end

    ExAws.S3.put_object(bucket(), key, binary, options)
    |> ExAws.request()
  end

  @doc """
  Downloads a file from S3 and returns its content as a binary.

  ## Options

  The `options` keyword list is passed directly to `ExAws.S3.get_object/3`.

  See `ExAws.S3.get_object/3` documentation for more details.
  """
  @impl Rescutex.CloudStorage.Adapters.AdapterBehaviour
  def download(key, options \\ []) do
    case ExAws.S3.get_object(bucket(), key, options) |> ExAws.request() do
      {:ok, %{body: file_binary}} -> {:ok, file_binary}
      {:error, _reason} = error -> error
    end
  end

  @impl Rescutex.CloudStorage.Adapters.AdapterBehaviour
  def list_objects() do
    bucket() |> ExAws.S3.list_objects() |> ExAws.request!() |> get_in([:body, :contents])
  end

  defp bucket do
    Application.get_env(:rescutex, Rescutex.CloudStorage)[:bucket] ||
      raise """
      S3 bucket not configured for #{__MODULE__}.
      Please add the following to your config file:
      config :rescutex, #{inspect(__MODULE__)},
        bucket: "your-s3-bucket-name"
      """
  end
end
