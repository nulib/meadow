defmodule Meadow.AWS.Response do
  @moduledoc """
  Normalizes aws-elixir responses into idiomatic Elixir data.

  aws-elixir hands back `{:ok, body, %{status_code:, headers:, body:}}` on success and
  `{:error, {:unexpected_response, response}}` for any status the operation didn't
  declare as successful. Bodies arrive with the wire's key names (`"ETag"`,
  `"CommonPrefixes"`) as strings, and because `AWS.XML` builds its maps by merging
  repeated tags, a single-element XML collection decodes to a bare map rather than a
  one-element list.

  This module is the one place those quirks are dealt with, so the rest of Meadow sees
  underscored atom keys, real lists, and flat error reasons.
  """

  @doc """
  Convert an aws-elixir result into `{:ok, value} | {:error, reason}`.

  `value` is what `fun` extracts from the normalized body and the raw response; with
  no `fun`, it's the normalized body.

  Errors collapse to `:not_found` / `:forbidden` for the statuses Meadow branches on,
  `{:http_error, status, body}` for anything else, and the underlying reason for
  transport failures.
  """
  def unwrap(result, fun \\ nil)

  def unwrap({:ok, body, _response}, nil), do: {:ok, body}

  def unwrap({:ok, body, response}, fun) when is_function(fun, 2),
    do: {:ok, fun.(body, response)}

  def unwrap({:ok, body, _response}, fun) when is_function(fun, 1),
    do: {:ok, fun.(body)}

  # aws-elixir compares the response status against the single success code in the AWS
  # service model, and those don't always match what S3 really sends — PutBucketPolicy is
  # modelled as 200 but answers 204. Any 2xx is a success; the body of such a response is
  # empty in practice, which is why there is nothing to decode here.
  def unwrap({:error, {:unexpected_response, %{status_code: status}}}, _fun)
      when status in 200..299,
      do: {:ok, nil}

  def unwrap({:error, {:unexpected_response, %{status_code: 403}}}, _fun),
    do: {:error, :forbidden}

  def unwrap({:error, {:unexpected_response, %{status_code: 404}}}, _fun),
    do: {:error, :not_found}

  def unwrap({:error, {:unexpected_response, %{status_code: status, body: body}}}, _fun),
    do: {:error, {:http_error, status, body}}

  def unwrap({:error, reason}, _fun), do: {:error, reason}

  @doc """
  Like `unwrap/2`, but raises `Meadow.AWS.Error` instead of returning an error tuple.
  """
  def unwrap!(result, fun \\ nil) do
    case unwrap(result, fun) do
      {:ok, value} ->
        value

      {:error, reason} ->
        raise Meadow.AWS.Error, message: "AWS request failed: #{inspect(reason)}"
    end
  end

  @doc """
  Discard a successful response body, keeping only success or failure.
  """
  def unwrap_status(result) do
    case unwrap(result) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc """
  Like `unwrap_status/1`, but raises on failure.
  """
  def unwrap_status!(result) do
    unwrap!(result)
    :ok
  end

  @doc """
  Recursively rewrite a decoded body: wire key names become underscored atoms and
  xmerl's `"__text"` catch-all becomes `:text`.
  """
  def normalize(nil), do: nil
  # `AWS.XML` folds an element's children starting from `:none`, so an empty element
  # (`<Delimiter/>`) comes back as the accumulator itself rather than a value.
  def normalize(:none), do: nil
  def normalize(list) when is_list(list), do: Enum.map(list, &normalize/1)

  def normalize(%{} = map),
    do: Map.new(map, fn {key, value} -> {normalize_key(key), normalize(value)} end)

  def normalize(value), do: value

  @doc """
  Coerce a decoded XML collection into a list.

  `AWS.XML` returns a bare map when a repeated tag appears exactly once and omits the
  key entirely when it appears zero times, so every collection has to come through
  here before it can be enumerated.
  """
  def list(nil), do: []
  def list(list) when is_list(list), do: list
  def list(value), do: [value]

  @doc """
  Look up a response header, case-insensitively.
  """
  def header(%{headers: headers}, name), do: header(headers, name)

  def header(headers, name) when is_list(headers) do
    downcased = String.downcase(name)

    Enum.find_value(headers, fn {header, value} ->
      if String.downcase(header) == downcased, do: value
    end)
  end

  @doc """
  Extract `x-amz-meta-*` headers as a map of string keys to values.

  Keys stay strings on purpose: object metadata is set by whoever uploaded the object,
  so atomizing it would let arbitrary uploads grow the atom table.
  """
  def metadata(%{headers: headers}), do: metadata(headers)

  def metadata(headers) when is_list(headers) do
    headers
    |> Enum.flat_map(fn {header, value} ->
      case header |> String.downcase() |> String.split("x-amz-meta-", parts: 2) do
        ["", key] -> [{key, value}]
        _ -> []
      end
    end)
    |> Enum.into(%{})
  end

  # Keys come from the AWS service schemas baked into aws-elixir, not from user data,
  # so the set is bounded and `String.to_atom/1` is safe here.
  defp normalize_key("__text"), do: :text
  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: key |> Macro.underscore() |> String.to_atom()
end
