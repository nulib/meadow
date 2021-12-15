defmodule Meadow.AwsError, do: defexception([:message])

defmodule Meadow.Utils.AWS do
  @moduledoc """
  Utility functions for AWS requests and object management
  """
  alias Meadow.Error
  alias Meadow.Utils.AWS.MultipartCopy

  import SweetXml, only: [sigil_x: 2]

  @doc """
  Drop-in replacement for ExAws.request/2 that reports errors to Honeybadger
  """
  def request(op, config_overrides \\ []) do
    ExAws.request(op, config_overrides) |> handle_response()
  end

  @doc """
  Drop-in replacement for ExAws.request!/2 that reports errors to Honeybadger
  """
  def request!(op, config_overrides \\ []) do
    case ExAws.request(op, config_overrides) |> handle_response() do
      {:ok, result} ->
        result

      error ->
        raise ExAws.Error, """
        ExAws Request Error!

        #{inspect(error)}
        """
    end
  end

  def presigned_url(bucket, %{upload_type: "preservation_check", filename: filename}) do
    generate_presigned_url(bucket, "#{filename}", :get)
  end

  def presigned_url(bucket, %{upload_type: "file_set", filename: filename}) do
    generate_presigned_url(bucket, "file_sets/#{Ecto.UUID.generate()}.#{Path.extname(filename)}")
  end

  def presigned_url(bucket, %{upload_type: "ingest_sheet"}) do
    generate_presigned_url(bucket, "ingest_sheets/#{Ecto.UUID.generate()}.csv")
  end

  def presigned_url(bucket, %{upload_type: "csv_metadata"}) do
    generate_presigned_url(bucket, "csv_metadata/#{Ecto.UUID.generate()}.csv")
  end

  def create_s3_folder(bucket, name) do
    bucket
    |> check_bucket()
    |> ExAws.S3.put_object("#{name}/.folder", "")
    |> request()
  end

  def add_aws_signature(request, region, access_key, secret) do
    request.headers ++ generate_aws_signature(request, region, access_key, secret)
  end

  def check_object_tags!(bucket, key, required_tags) do
    case ExAws.S3.get_object_tagging(bucket, key) |> ExAws.request() do
      {:ok, %{status_code: 200, body: %{tags: actual_tags}}} ->
        existing_tags = Enum.map(actual_tags, &Map.get(&1, :key))
        required_tags -- existing_tags == []

      other ->
        raise "Unexpected response: #{other}"
    end
  end

  def copy_object(dest_bucket, dest_object, src_bucket, src_object, opts \\ []),
    do: MultipartCopy.copy_object(dest_bucket, dest_object, src_bucket, src_object, opts)

  defp generate_aws_signature(request, region, access_key, secret) do
    signed_request =
      Sigaws.sign_req(
        request.url,
        method: request.method |> to_string() |> String.upcase(),
        headers: request.headers,
        body: request.body,
        service: "es",
        region: region,
        access_key: access_key,
        secret: secret
      )

    case signed_request do
      {:ok, headers, _} -> headers |> Enum.into([])
      other -> other
    end
  end

  defp check_bucket(bucket) do
    case bucket |> ensure_bucket_exists() do
      {:ok, _} -> bucket
      {:error, message} -> raise message
      other -> raise other
    end
  end

  defp ensure_bucket_exists(bucket) do
    case bucket do
      :undefined ->
        {:error, "Bucket: #{bucket} not configured"}

      bucket ->
        case bucket |> ExAws.S3.head_bucket() |> ExAws.request() do
          {:error, {:http_error, 404, _}} ->
            bucket
            |> ExAws.S3.put_bucket("us-east-1")
            |> request!()

            {:ok, :created}

          {:ok, _} ->
            {:ok, :exists}

          other ->
            other
        end
    end
  end

  defp generate_presigned_url(bucket, path, method \\ :put) do
    bucket
    |> check_bucket()

    ExAws.S3.presigned_url(ExAws.Config.new(:s3), method, bucket, path)
  end

  def handle_response(response) do
    {:current_stacktrace, [_ | [_ | stacktrace]]} = Process.info(self(), :current_stacktrace)
    [{module, _, _, _} | _] = stacktrace

    case response do
      {:error, {:http_error, _status, response}} ->
        {message, context} = extract_aws_error(response)
        Error.report(%Meadow.AwsError{message: message}, module, stacktrace, context)

      {:error, message} ->
        Error.report(%Meadow.AwsError{message: to_string(message)}, module, stacktrace)

      _ ->
        :noop
    end

    response
  end

  def handle_response!(response) do
    case handle_response(response) do
      {:ok, result} ->
        result

      error ->
        raise ExAws.Error, """
        ExAws Request Error!

        #{inspect(error)}
        """
    end
  end

  defp extract_aws_error(%{body: body, status_code: status_code}) do
    case SweetXml.parse(body) |> SweetXml.xpath(~x"/Error") do
      nil ->
        status_code

      {:xmlElement, :Error, _, _, _, _, _, _, children, _, _, _} ->
        context = map_children(children) |> Enum.reject(&is_nil/1) |> Enum.into(%{})
        {code, context} = Map.pop(context, :Code)
        {message, context} = Map.pop(context, :Message)
        message = "#{status_code} (#{code}): #{message}"

        {message, context}
    end
  end

  defp extract_aws_error(%{status_code: status_code}), do: {to_string(status_code), %{}}

  defp map_children([]), do: []
  defp map_children([child | children]), do: [map_child(child) | map_children(children)]

  defp map_child(child) do
    case child do
      {:xmlElement, tag, _, _, _, _, _, _, _, _, _, _} ->
        {tag, SweetXml.xpath(child, ~x"./text()") |> to_string()}

      _ ->
        nil
    end
  end
end
