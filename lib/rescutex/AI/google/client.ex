defmodule Rescutex.AI.Google.Client do
  @moduledoc """
  Client to interact with Google Vertex AI (Gemini and Multimodal Embeddings).
  """

  require Logger
  alias Rescutex.AI.Error

  # Configuration (Defaults provided, can be overridden via config/*.exs)
  @project_id Application.compile_env(:rescutex, :google_project_id, "rescutex")
  @location Application.compile_env(:rescutex, :google_location, "us-central1")
  @goth_instance Rescutex.Goth

  # API Config
  @base_url "https://#{@location}-aiplatform.googleapis.com/v1/projects/#{@project_id}/locations/#{@location}"
  @edit_model "imagen-3.0-capability-001"
  @embed_model "multimodalembedding@001"

  # Timeout configuration
  @timeout 100_000

  @type error_response :: {:error, Error.t()}
  @type success_response :: {:ok, map()} | {:ok, list(float())} | {:ok, binary()}

  @doc """
  Builds the dynamic client with authentication headers.
  """
  def client do
    token = fetch_token!()

    middleware = [
      {Tesla.Middleware.BaseUrl, @base_url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{token}"}]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: @timeout}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Sends an image to Imagen to remove the background.

  ## Arguments
  * `image_binary` - The raw binary content of the image.
  * `mime_type` - (Optional) Mime type, defaults to "image/jpeg".
  """
  @spec remove_background(binary(), String.t()) :: success_response() | error_response()
  def remove_background(image_binary, _mime_type \\ "image/jpeg") do
    uri = "/publishers/google/models/#{@edit_model}:predict"

    # CHANGE 1: The prompt must describe the NEW background only.
    # Do not include instructions like "remove" or "do not alter subject".
    prompt = "clean solid white background"

    # 2. Negative Prompt: Explicitly forbid the "invented" stuff.
    negative_prompt =
      "shadows, contact shadows, floor, wall, horizon line, 3d render, realistic texture, lighting effects, gradient, artifacts, noise"

    body = %{
      instances: [
        %{
          prompt: prompt,
          referenceImages: [
            %{
              referenceType: "REFERENCE_TYPE_RAW",
              referenceId: 1,
              referenceImage: %{
                bytesBase64Encoded: Base.encode64(image_binary)
              }
            },
            %{
              referenceType: "REFERENCE_TYPE_MASK",
              referenceId: 2,
              maskImageConfig: %{
                maskMode: "MASK_MODE_BACKGROUND"
              }
            }
          ]
        }
      ],
      parameters: %{
        sampleCount: 1,
        editMode: "EDIT_MODE_BGSWAP",
        guidanceScale: 200,
        negativePrompt: negative_prompt
      }
    }

    Tesla.post(client(), uri, body)
    |> handle_response()
    |> parse_edit_response()
  end

  @doc """
  Creates a multimodal embedding for an image.
  """
  @spec create_embedding(binary()) :: {:ok, list(float())} | error_response()
  def create_embedding(image_binary) do
    uri = "/publishers/google/models/#{@embed_model}:predict"

    body = %{
      instances: [
        %{
          image: %{
            bytesBase64Encoded: Base.encode64(image_binary)
          }
        }
      ]
    }

    Tesla.post(client(), uri, body)
    |> handle_response()
    |> parse_embedding_response()
  end

  # ==========================================
  # Private Helpers & Response Handling
  # ==========================================

  defp fetch_token! do
    case Goth.fetch(@goth_instance) do
      {:ok, %{token: token}} -> token
      {:error, reason} -> raise "Failed to fetch Google Auth token: #{inspect(reason)}"
    end
  end

  # Generic HTTP handling
  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}), do: {:ok, body}

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}) do
    Logger.warning("Google API Error [#{status}]: #{inspect(body)}")
    error_info = Map.get(body, "error", %{})

    message = Map.get(error_info, "message", "Unknown API Error")
    reason = error_info |> Map.get("status") |> parse_reason_string()

    {:error, Error.new(reason, status, message)}
  end

  defp handle_response({:error, :econnrefused}),
    do: {:error, Error.new(:econnrefused, 503, "Server down")}

  defp handle_response({:error, :timeout}),
    do: {:error, Error.new(:timeout, 408, "Timeout error")}

  defp handle_response({:error, reason}) do
    Logger.error("Internal Client Error: #{inspect(reason)}")
    {:error, Error.new(:internal_error, 500, "Unknown internal client error")}
  end

  # Specific Parsing Logic for Imagen Generation
  defp parse_edit_response({:error, _} = error), do: error

  defp parse_edit_response({:ok, body}) do
    try do
      case body do
        %{"predictions" => [%{"bytesBase64Encoded" => base64} | _]} ->
          {:ok, Base.decode64!(base64)}

        %{"predictions" => [base64 | _]} when is_binary(base64) ->
          {:ok, Base.decode64!(base64)}

        _ ->
          Logger.error("Unexpected Imagen response: #{inspect(body)}")
          {:error, Error.new(:parsing_error, 500, "Invalid edit response format")}
      end
    rescue
      e ->
        Logger.error("Failed to decode Imagen response: #{inspect(e)}")
        {:error, Error.new(:parsing_error, 500, "Failed to decode image")}
    end
  end

  # Specific Parsing Logic for Embeddings
  defp parse_embedding_response({:error, _} = error), do: error

  defp parse_embedding_response({:ok, body}) do
    try do
      %{"predictions" => [%{"imageEmbedding" => embedding} | _]} = body
      {:ok, embedding}
    rescue
      _ -> {:error, Error.new(:parsing_error, 500, "Invalid embedding response format")}
    end
  end

  defp parse_reason_string("INVALID_ARGUMENT"), do: :invalid_argument
  defp parse_reason_string("PERMISSION_DENIED"), do: :permission_denied
  defp parse_reason_string(_), do: :unexpected_error
end
