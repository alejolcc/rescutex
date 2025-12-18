defmodule Rescutex.AI.Google.Client do
  @moduledoc """
  Client to interact with Google Vertex AI (Gemini and Multimodal Embeddings).
  """

  use Tesla
  require Logger
  alias Rescutex.AI.Error

  # Configuration (Defaults provided, can be overridden via config/*.exs)
  @project_id Application.compile_env(:rescutex, :google_project_id, "rescutex")
  @location Application.compile_env(:rescutex, :google_location, "us-central1")
  @goth_instance Rescutex.Goth

  # API Config
  @base_url "https://#{@location}-aiplatform.googleapis.com/v1/projects/#{@project_id}/locations/#{@location}"
  @gen_model "gemini-2.0-flash-preview-image-generation"
  @embed_model "multimodalembedding@001"

  # Timeout configuration
  @timeout 100_000

  @type error_response :: {:error, Error.t()}
  @type success_response :: {:ok, map()} | {:ok, list(float())}

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: @timeout

  @doc """
  Builds the dynamic client with authentication headers.
  """
  def client do
    token = fetch_token!()

    middleware = [
      {Tesla.Middleware.BaseUrl, @base_url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{token}"}]}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Sends an image to Gemini to remove the background.

  ## Arguments
  * `image_binary` - The raw binary content of the image.
  * `mime_type` - (Optional) Mime type, defaults to "image/jpeg".
  """
  @spec remove_background(binary(), String.t()) :: success_response() | error_response()
  def remove_background(image_binary, mime_type \\ "image/jpeg") do
    uri = "/publishers/google/models/#{@gen_model}:generateContent"

    prompt = """
    This is a picture of a pet I need to compare with other pets.
    Remove the existing background from this image and replace it with a solid white background.
    Do not alter or modify the subject in any way. Ensure the subject remains clear, well-defined,
    and perfectly preserved.
    """

    body = %{
      contents: %{
        role: "USER",
        parts: [
          %{
            inline_data: %{
              mime_type: mime_type,
              data: Base.encode64(image_binary)
            }
          },
          %{text: prompt}
        ]
      },
      generation_config: %{
        temperature: 0.0,
        response_modalities: ["TEXT", "IMAGE"]
      },
      safetySettings: [
        %{
          category: "HARM_CATEGORY_DANGEROUS_CONTENT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    }

    # Use the dynamic client
    client()
    |> post(uri, body)
    |> handle_response()
    |> parse_generation_response()
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

    client()
    |> post(uri, body)
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

  # Specific Parsing Logic for Gemini Generation
  defp parse_generation_response({:error, _} = error), do: error

  defp parse_generation_response({:ok, body}) do
    usage_metadata = Map.get(body, "usageMetadata", %{})

    Logger.info("Gemini Usage: #{inspect(usage_metadata)}")

    # Check if content was actually generated or blocked
    case Map.get(body, "candidates") do
      nil -> extract_block_reason(body)
      [] -> extract_block_reason(body)
      _candidates -> {:ok, body}
    end
  end

  defp extract_block_reason(body) do
    reason =
      body
      |> Map.get("promptFeedback", %{})
      |> Map.get("blockReason", "Unknown Block Reason")

    {:error, Error.new(:blocked, 400, "Content generation blocked: #{reason}")}
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
