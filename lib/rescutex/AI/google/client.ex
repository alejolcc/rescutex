defmodule Rescutex.AI.Google.Client do
  @moduledoc """
  Client to interact with the Gemini API.

  RAG Docs: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/rag-api-v1#list-rag-files-example-api
  """

  alias Rescutex.AI.Error

  require Logger

  use Tesla
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.BaseUrl, @base_url
  plug Tesla.Middleware.Timeout, timeout: 100_000
  # @base_url "https://generativelanguage.googleapis.com"
  @project_id "rescutex"
  @base_url "https://us-central1-aiplatform.googleapis.com/v1/projects/#{@project_id}/locations/us-central1"
  # @model "gemini-1.5-pro"
  @model "gemini-2.0-flash"
  # @model "gemini-2.0-flash-exp"

  def generate_content(prompt, system_instruction, opts \\ []) do
    uri =
      "/publishers/google/models/#{@model}:generateContent"

    auth = Goth.fetch!(Rescutex.Goth) |> Map.get(:token)
    body = generate_content_body(prompt, system_instruction, opts)

    with {:ok, body, _headers} <-
           post(uri, body, headers: [{"Authorization", "Bearer #{auth}"}]) |> handle_response() do
      usage_metadata = Map.get(body, "usageMetadata")

      Logger.info(inspect(usage_metadata))
      Logger.debug("Body: #{inspect(body)}")

      if usage_metadata["candidatesTokenCount"] && usage_metadata["candidatesTokenCount"] > 0 do
        {:ok, body}
      else
        message =
          body
          |> Map.get("promptFeedback", %{})
          |> Map.get("blockReason", "Not available")

        {:error, Error.new(:internal_error, 500, message)}
      end
    end
  end

  def get_upload_url(file_path) do
    Logger.info("Getting upload url for file: #{file_path}")
    uri = "/upload/v1beta/files?key=#{api_key()}"

    %{size: size} = File.stat!(file_path)

    body = %{
      file: %{
        display_name: Path.basename(file_path)
      }
    }

    headers =
      [
        {"X-Goog-Upload-Protocol", "resumable"},
        {"X-Goog-Upload-Command", "start"},
        {"X-Goog-Upload-Header-Content-Length", "#{size}"},
        {"X-Goog-Upload-Header-Content-Type", "application/pdf"},
        {"Content-Type", "application/json"}
      ]

    with {:ok, _body, headers} <- post(uri, body, headers: headers) |> handle_response() do
      {_header, val} = Enum.find(headers, fn {header, _val} -> header == "x-goog-upload-url" end)

      {:ok, val}
    end
  end

  def upload_file(upload_url, file_path) do
    Logger.info("Uploading file: #{file_path}")
    uri = upload_url
    %{size: size} = File.stat!(file_path)

    headers = [
      {"Content-Length", "#{size}"},
      {"X-Goog-Upload-Offset", "0"},
      {"X-Goog-Upload-Command", "upload, finalize"}
    ]

    body = File.read!(file_path)

    with {:ok, body, _headers} <- post(uri, body, headers: headers) |> handle_response() do
      {:ok, body["file"]}
    end
  end

  def remove_background(file_path) do
    uri = "/publishers/google/models/gemini-2.0-flash-preview-image-generation:generateContent"

    prompt =
      """
      This is a picture of a pet I need to compare the pet with others pets,
      can you remove all the background and keep only the same image of the pet with background white.
      Do not change anything from the original pet, mantain all the morfology
      """

    auth = Goth.fetch!(Rescutex.Goth) |> Map.get(:token)

    headers = [
      {"Authorization", "Bearer #{auth}"},
      {"Content-Type", "application/json"},
      {"charset", "utf-8"}
    ]

    body = %{
      contents: %{
        role: "USER",
        parts: [
          %{inline_data: %{mime_type: "image/jpg", data:  File.read!(file_path) |> :base64.encode()}},
          %{text: prompt}
        ]
      },
      generation_config: %{
        response_modalities: ["TEXT", "IMAGE"]
      },
      safetySettings: %{
        method: "PROBABILITY",
        category: "HARM_CATEGORY_DANGEROUS_CONTENT",
        threshold: "BLOCK_MEDIUM_AND_ABOVE"
      }
    }

    with {:ok, body, _headers} <- post(uri, body, headers: headers) |> handle_response() do
      usage_metadata = Map.get(body, "usageMetadata")

      Logger.info(inspect(usage_metadata))
      Logger.debug("Body: #{inspect(body)}")

      if usage_metadata["candidatesTokenCount"] && usage_metadata["candidatesTokenCount"] > 0 do
        {:ok, body}
      else
        message =
          body
          |> Map.get("promptFeedback", %{})
          |> Map.get("blockReason", "Not available")

        {:error, Error.new(:internal_error, 500, message)}
      end
    end
  end

  def create_embedding(file_path) do
    uri = "/publishers/google/models/multimodalembedding@001:predict"

    auth = Goth.fetch!(Rescutex.Goth) |> Map.get(:token)

    headers = [
      {"Authorization", "Bearer #{auth}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      instances: [
        %{
          image: %{
            bytesBase64Encoded: File.read!(file_path) |> :base64.encode()
          }
        }
      ]
    }

    with {:ok, body, _headers} <- post(uri, body, headers: headers) |> handle_response() do
      %{"predictions" => [%{"imageEmbedding" => embedding}]} = body
      {:ok, embedding}
    end
  end

  ###########
  # Private #
  ###########

  defp handle_response({:ok, %Tesla.Env{status: 200, body: body, headers: headers}}) do
    {:ok, body, headers}
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}) do
    message = body |> Map.get("error") |> Map.get("message")
    reason = body |> Map.get("error") |> Map.get("status") |> reason()
    {:error, Error.new(reason, status, message)}
  end

  defp handle_response({:error, :econnrefused}) do
    {:error, Error.new(:econnrefused, 503, "Server down")}
  end

  defp handle_response({:error, :timeout}) do
    {:error, Error.new(:timeout, 408, "Timeout error")}
  end

  defp handle_response(error) do
    Logger.error("Error: #{inspect(error)}")
    {:error, Error.new(:internal_error, 500, "Unknown error")}
  end

  defp reason("INVALID_ARGUMENT"), do: :invalid_argument
  defp reason("PERMISSION_DENIED"), do: :permission_denied
  defp reason(_), do: :unexpected_error

  defp generate_content_body(prompt, system_instruction, opts) do
    file_uri = opts[:file_uri] || nil
    file_data = opts[:file_data] || nil
    use_rag? = opts[:use_rag] || nil

    prompt = %{text: prompt}

    file_uri = file_uri && %{file_data: %{mime_type: "application/pdf", file_uri: file_uri}}
    file_data = file_data && %{inline_data: %{mime_type: "application/pdf", data: file_data}}

    parts =
      [prompt, file_uri, file_data]
      |> Enum.filter(& &1)

    contents = [
      %{
        role: "user",
        parts: parts
      }
    ]

    system_instruction = %{
      parts: [
        %{text: system_instruction}
      ]
    }

    tools = %{
      retrieval: %{
        disable_attribution: false,
        vertex_rag_store: %{
          rag_resources: %{
            rag_corpus:
              "projects/97522503747/locations/us-central1/ragCorpora/6917529027641081856"
          },
          similarity_top_k: 10,
          vector_distance_threshold: 0.7
        }
      }
    }

    tools = use_rag? && tools

    safety_settings = [
      %{category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE"},
      %{category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE"},
      %{category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE"},
      %{category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE"}
    ]

    config = opts[:config] || %{}

    %{}
    |> Map.put(:contents, contents)
    |> Map.put(:systemInstruction, system_instruction)
    |> Map.put(:safetySettings, safety_settings)
    |> Map.put(:generationConfig, config)
    |> Map.put(:tools, tools)
  end

  defp api_key do
    System.fetch_env!("IA_GOOGLE_API_KEY")
  end
end
