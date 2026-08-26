defmodule Meadow.AWS.S3 do
  @moduledoc """
  The S3 operations Meadow uses, on top of aws-elixir's generated `AWS.S3` module.

  Three things aws-elixir doesn't provide are implemented here:

    * **Presigned URLs** (`presigned_url/4`) via `:aws_signature.sign_v4_query_params/8`.
    * **Paginated listing** (`stream_objects/2`), since aws-elixir returns one page.
    * **Streaming reads and chunked uploads** (`stream_object/2`, `upload_file/3`),
      since aws-elixir's HTTP clients buffer whole bodies in memory.

  Every function returns idiomatic `:ok` / `{:ok, value}` / `{:error, reason}`; see
  `Meadow.AWS.Response` for the error vocabulary. Bang variants raise
  `Meadow.AWS.Error`.
  """

  # `AWS.*` refers to aws-elixir's generated modules throughout. Meadow.AWS is spelled
  # out in full rather than aliased, because aliasing it would make `AWS.S3` resolve to
  # this module instead of aws-elixir's.
  alias Meadow.AWS.Response

  require Logger

  # S3's floor for every part but the last.
  @min_part_size 5 * 1024 * 1024
  # S3's ceiling for a single DeleteObjects request.
  @max_delete_keys 1000
  @default_expires_in 3600

  ## Objects

  @doc """
  Fetch an object's body.
  """
  def get_object(bucket, key) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.get_object(bucket, object_key(key))
    |> Response.unwrap(&body/1)
  end

  def get_object!(bucket, key), do: unwrap_bang(get_object(bucket, key))

  @doc """
  Write an object.

  Options are the ones Meadow actually uses: `:content_type`, `:cache_control`,
  `:acl`, `:tagging`, and `:metadata` (a map merged into `x-amz-meta-*` headers).
  """
  def put_object(bucket, key, content, opts \\ []) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.put_object(bucket, object_key(key), put_object_input(content, opts))
    |> Response.unwrap_status()
  end

  def put_object!(bucket, key, content, opts \\ []),
    do: unwrap_bang(put_object(bucket, key, content, opts))

  @doc """
  Object metadata from a HEAD request.

  S3 answers HEAD with headers and no body, so everything interesting is read off the
  response headers rather than a parsed body.
  """
  def head_object(bucket, key) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.head_object(bucket, object_key(key), %{})
    |> Response.unwrap(fn _body, response ->
      %{
        content_length: response |> Response.header("content-length") |> to_integer(),
        content_type: Response.header(response, "content-type"),
        etag: response |> Response.header("etag") |> unquote_etag(),
        last_modified: Response.header(response, "last-modified"),
        metadata: Response.metadata(response),
        headers: response.headers
      }
    end)
  end

  def head_object!(bucket, key), do: unwrap_bang(head_object(bucket, key))

  @doc """
  Whether an object exists.
  """
  def object_exists?(bucket, key) do
    case head_object(bucket, key) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Delete an object. Succeeds whether or not the object was there.
  """
  def delete_object(bucket, key) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.delete_object(bucket, object_key(key), %{})
    |> Response.unwrap_status()
  end

  def delete_object!(bucket, key), do: unwrap_bang(delete_object(bucket, key))

  @doc """
  Delete many objects, batching into S3's #{@max_delete_keys}-key limit per request.

  Accepts anything enumerable, including a `stream_objects/2` stream.
  """
  def delete_objects(bucket, keys) do
    keys
    |> Stream.chunk_every(@max_delete_keys)
    |> Enum.reduce_while(:ok, fn batch, _acc ->
      input = %{
        "Delete" => %{"Object" => Enum.map(batch, &%{"Key" => object_key(&1)}), "Quiet" => true}
      }

      case Meadow.AWS.client(:s3)
           |> AWS.S3.delete_objects(bucket, input)
           |> Response.unwrap_status() do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  @doc """
  Server-side copy. `opts` accepts the same keys as `put_object/4` plus
  `:metadata_directive` and `:tagging_directive`.
  """
  def copy_object(dest_bucket, dest_key, src_bucket, src_key, opts \\ []) do
    input =
      opts
      |> copy_object_input()
      |> Map.put("CopySource", copy_source(src_bucket, src_key))

    Meadow.AWS.client(:s3)
    |> AWS.S3.copy_object(dest_bucket, object_key(dest_key), input)
    |> Response.unwrap(fn body ->
      %{etag: body |> get_in([:copy_object_result, :e_tag]) |> unquote_etag()}
    end)
  end

  def copy_object!(dest_bucket, dest_key, src_bucket, src_key, opts \\ []),
    do: unwrap_bang(copy_object(dest_bucket, dest_key, src_bucket, src_key, opts))

  ## Tagging

  @doc """
  An object's tag set as a list of `%{key: _, value: _}`.
  """
  def get_object_tagging(bucket, key) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.get_object_tagging(bucket, object_key(key))
    |> Response.unwrap(&unwrap_tag_body/1)
  end

  defp unwrap_tag_body(%{"Tagging" => %{"TagSet" => :none}}), do: []

  defp unwrap_tag_body(body) do
    body
    |> get_in(["Tagging", "TagSet", "Tag"])
    |> Response.list()
    |> Response.normalize()
  end

  def get_object_tagging!(bucket, key), do: unwrap_bang(get_object_tagging(bucket, key))

  @doc """
  Whether an object carries every one of `required_tags`.
  """
  def has_tags?(bucket, key, required_tags) do
    case get_object_tagging(bucket, key) do
      {:ok, tags} -> required_tags -- Enum.map(tags, & &1.key) == []
      other -> other
    end
  end

  def delete_object_tagging(bucket, key) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.delete_object_tagging(bucket, object_key(key), %{})
    |> Response.unwrap_status()
  end

  def delete_object_tagging!(bucket, key), do: unwrap_bang(delete_object_tagging(bucket, key))

  ## Listing

  @doc """
  One page of a bucket listing.

  Returns `%{objects: [...], prefixes: [...], key_count: n, continuation_token: token}`,
  where `continuation_token` is `nil` on the last page. Options: `:prefix`,
  `:delimiter`, `:max_keys`, `:continuation_token`.
  """
  def list_objects(bucket, opts \\ []) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.list_objects_v2(
      bucket,
      Keyword.get(opts, :continuation_token),
      Keyword.get(opts, :delimiter),
      nil,
      nil,
      Keyword.get(opts, :max_keys),
      Keyword.get(opts, :prefix)
    )
    |> Response.unwrap(&parse_listing/1)
  end

  def list_objects!(bucket, opts \\ []), do: unwrap_bang(list_objects(bucket, opts))

  @doc """
  Lazily stream every object in a bucket, following continuation tokens.

  Replaces `ExAws.stream!/1` over a listing operation. Each element is
  `%{key: _, size: _, etag: _, last_modified: _}`.
  """
  def stream_objects(bucket, opts \\ []) do
    Stream.resource(
      fn -> {:cont, nil} end,
      fn
        :done ->
          {:halt, :done}

        {:cont, token} ->
          listing = list_objects!(bucket, Keyword.put(opts, :continuation_token, token))

          case listing.continuation_token do
            nil -> {listing.objects, :done}
            next -> {listing.objects, {:cont, next}}
          end
      end,
      fn _ -> :ok end
    )
  end

  ## Buckets

  @doc """
  Whether a bucket exists and we can see it.
  """
  def bucket_exists?(bucket) do
    case Meadow.AWS.client(:s3) |> AWS.S3.head_bucket(bucket, %{}) |> Response.unwrap_status() do
      :ok -> true
      _ -> false
    end
  end

  @doc """
  Create a bucket. `us-east-1` takes no location constraint.
  """
  def create_bucket(bucket, region \\ nil) do
    region = region || Meadow.AWS.region()

    input =
      if region in [nil, "us-east-1"],
        do: %{},
        else: %{"CreateBucketConfiguration" => %{"LocationConstraint" => region}}

    Meadow.AWS.client(:s3)
    |> AWS.S3.create_bucket(bucket, input)
    |> Response.unwrap_status()
  end

  def create_bucket!(bucket, region \\ nil), do: unwrap_bang(create_bucket(bucket, region))

  def delete_bucket(bucket) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.delete_bucket(bucket, %{})
    |> Response.unwrap_status()
  end

  @doc """
  Every bucket name the current credentials can see.
  """
  def list_buckets do
    Meadow.AWS.client(:s3)
    |> AWS.S3.list_buckets()
    |> Response.unwrap(fn body ->
      body
      |> get_in([:list_all_my_buckets_result, :buckets, :bucket])
      |> Response.list()
      |> Enum.map(& &1.name)
    end)
  end

  def list_buckets!, do: unwrap_bang(list_buckets())

  def put_bucket_policy(bucket, policy) when is_binary(policy) do
    # PutBucketPolicy's payload is the raw policy JSON. aws-elixir would otherwise
    # XML-encode the input map and S3 would reject it as a malformed policy.
    Meadow.AWS.client(:s3)
    |> AWS.S3.put_bucket_policy(bucket, %{"Body" => policy}, send_body_as_binary?: true)
    |> Response.unwrap_status()
  end

  def put_bucket_policy(bucket, policy), do: put_bucket_policy(bucket, Jason.encode!(policy))

  def put_bucket_policy!(bucket, policy), do: unwrap_bang(put_bucket_policy(bucket, policy))

  @doc """
  Set a bucket's notification configuration. `configuration` is the inner
  `NotificationConfiguration` map, e.g.

      %{"CloudFunctionConfiguration" => %{"Event" => [...], "CloudFunction" => arn}}
  """
  def put_bucket_notification_configuration(bucket, configuration) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.put_bucket_notification_configuration(bucket, %{
      "NotificationConfiguration" => configuration
    })
    |> Response.unwrap_status()
  end

  ## Multipart

  def create_multipart_upload(bucket, key, opts \\ []) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.create_multipart_upload(bucket, object_key(key), copy_object_input(opts))
    |> Response.unwrap(fn body ->
      get_in(body, ["InitiateMultipartUploadResult", "UploadId"])
    end)
  end

  def upload_part(bucket, key, upload_id, part_number, content, opts \\ []) do
    input = %{
      "Body" => content,
      "PartNumber" => part_number,
      "UploadId" => upload_id
    }

    Meadow.AWS.client(:s3)
    |> AWS.S3.upload_part(bucket, object_key(key), input, request_opts(opts))
    |> Response.unwrap(fn _body, response ->
      response |> Response.header("etag") |> unquote_etag()
    end)
  end

  @doc """
  Copy a byte range of `src` into one part of an in-progress multipart upload.
  """
  def upload_part_copy(
        bucket,
        key,
        upload_id,
        part_number,
        {src_bucket, src_key},
        range,
        opts \\ []
      ) do
    input = %{
      "CopySource" => copy_source(src_bucket, src_key),
      "CopySourceRange" => range,
      "PartNumber" => part_number,
      "UploadId" => upload_id
    }

    Meadow.AWS.client(:s3)
    |> AWS.S3.upload_part_copy(bucket, object_key(key), input, request_opts(opts))
    |> Response.unwrap(fn body ->
      body |> get_in([:copy_part_result, :e_tag]) |> unquote_etag()
    end)
  end

  @doc """
  Finish a multipart upload. `parts` is a list of `{part_number, etag}`.
  """
  def complete_multipart_upload(bucket, key, upload_id, parts) do
    input = %{
      "UploadId" => upload_id,
      "CompleteMultipartUpload" => %{
        "Part" =>
          Enum.map(parts, fn {number, etag} -> %{"PartNumber" => number, "ETag" => etag} end)
      }
    }

    Meadow.AWS.client(:s3)
    |> AWS.S3.complete_multipart_upload(bucket, object_key(key), input)
    |> Response.unwrap(fn body -> Map.get(body, :complete_multipart_upload_result, %{}) end)
  end

  def abort_multipart_upload(bucket, key, upload_id) do
    Meadow.AWS.client(:s3)
    |> AWS.S3.abort_multipart_upload(bucket, object_key(key), %{"UploadId" => upload_id})
    |> Response.unwrap_status()
  end

  ## Presigned URLs

  @doc """
  A presigned URL for `method` on `bucket`/`key`.

  aws-elixir has no presigning support, so this signs the query string directly with
  `:aws_signature`. Options: `:expires_in` (seconds, default #{@default_expires_in}).
  """
  def presigned_url(method, bucket, key, opts \\ []) do
    client = Meadow.AWS.client(:s3)

    case client do
      %{access_key_id: access_key_id, secret_access_key: secret} when is_binary(access_key_id) ->
        url =
        [
          Meadow.AWS.endpoint_url(client, Meadow.AWS.host(client, "s3")),
          AWS.Util.encode_uri(bucket),
          object_key(key)
        ]
        |> Enum.join("/")

      signed =
        :aws_signature.sign_v4_query_params(
          access_key_id,
          secret,
          client.region,
          "s3",
          NaiveDateTime.utc_now() |> NaiveDateTime.to_erl(),
          method |> to_string() |> String.upcase(),
          url,
          presign_options(client, opts)
        )

      {:ok, signed}
      _ -> {:error, :no_credentials}
    end
  end

  ## Streaming

  @doc """
  Stream an object's body in chunks without buffering the whole thing.

  aws-elixir's HTTP clients read the full body into memory, so this presigns a GET and
  hands the URL to `Meadow.Utils.Stream`, which already streams HTTP responses through
  Req.
  """
  def stream_object(bucket, key) do
    case presigned_url(:get, bucket, key) do
      {:ok, url} ->
        Meadow.Utils.Stream.stream_from(url)

      {:error, reason} ->
        raise Meadow.AWS.Error,
          message: "Unable to presign s3://#{bucket}/#{key} for streaming: #{inspect(reason)}"
    end
  end

  @doc """
  Upload a local file, switching to a multipart upload above #{@min_part_size} bytes.

  Replaces `ExAws.S3.Upload`. `opts` accepts the same keys as `put_object/4`, plus
  `:chunk_size` and `:max_concurrency`.
  """
  def upload_file(path, bucket, key, opts \\ []) do
    %{size: size} = File.stat!(path)
    {chunk_size, opts} = Keyword.pop(opts, :chunk_size, @min_part_size)

    if size > chunk_size do
      multipart_upload_file(path, bucket, key, max(chunk_size, @min_part_size), opts)
    else
      put_object(bucket, key, File.read!(path), opts)
    end
  end

  def upload_file!(path, bucket, key, opts \\ []),
    do: unwrap_bang(upload_file(path, bucket, key, opts))

  defp multipart_upload_file(path, bucket, key, chunk_size, opts) do
    {max_concurrency, opts} = Keyword.pop(opts, :max_concurrency, 10)

    with {:ok, upload_id} <- create_multipart_upload(bucket, key, opts) do
      chunker = fn {chunk, part_number} ->
        {:ok, etag} = upload_part(bucket, key, upload_id, part_number, chunk)
        {:ok, {part_number, etag}}
      end

      parts =
        path
        |> File.stream!(chunk_size, [])
        |> Stream.with_index(1)
        |> Task.async_stream(
          chunker,
          max_concurrency: max_concurrency,
          timeout: :infinity
        )
        |> Enum.map(fn
          {:ok, {:ok, part}} -> part
          other -> {:error, other}
        end)

      Enum.find(parts, &match?({:error, _}, &1))
      |> resolve_multipart_upload(path, bucket, key, upload_id, parts)
    end
  end

  defp resolve_multipart_upload(nil, _path, bucket, key, upload_id, parts) do
    with {:ok, _} <- complete_multipart_upload(bucket, key, upload_id, parts), do: :ok
  end

  defp resolve_multipart_upload({:error, reason}, path, bucket, key, upload_id, _parts) do
    Logger.error("Multipart upload of #{path} failed: #{inspect(reason)}")
    abort_multipart_upload(bucket, key, upload_id)
    {:error, reason}
  end

  ## Helpers

  defp parse_listing(body) do
    result =
      body
      |> Map.get("ListBucketResult", %{})

    %{
      objects:
        result
        |> Map.get("Contents")
        |> Response.list()
        |> Enum.map(fn object ->
          %{
            key: object |> Map.get("Key"),
            size: object |> Map.get("Size") |> to_integer(),
            etag: object |> Map.get("ETag") |> unquote_etag(),
            last_modified: Map.get(object, "LastModified")
          }
        end),
      prefixes:
        result
        |> Map.get("CommonPrefixes")
        |> Response.list()
        |> Enum.map(& &1["Prefix"]),
      key_count: result |> Map.get("KeyCount") |> to_integer(),
      continuation_token:
        if Map.get(result, "IsTruncated") == "true" do
          Map.get(result, "NextContinuationToken")
        end
    }
  end

  defp put_object_input(content, opts) do
    opts
    |> copy_object_input()
    |> Map.put("Body", content)
  end

  @input_keys %{
    acl: "ACL",
    cache_control: "CacheControl",
    content_type: "ContentType",
    meta: "Metadata",
    metadata: "Metadata",
    metadata_directive: "MetadataDirective",
    tagging: "Tagging",
    tagging_directive: "TaggingDirective"
  }

  # Options consumed by Meadow rather than sent to S3.
  @passthrough_keys [:chunk_size, :max_concurrency, :expires_in] ++
                      [:receive_timeout, :request_timeout, :pool_timeout]

  defp copy_object_input(opts) do
    Enum.reduce(opts, %{}, fn {key, value}, input ->
      cond do
        name = Map.get(@input_keys, key) -> Map.put(input, name, normalize_input(name, value))
        key in @passthrough_keys -> input
        # Silently dropping an option here would quietly lose metadata or tags, so make
        # an unrecognized one a hard error instead.
        true -> raise ArgumentError, "unsupported S3 option: #{inspect(key)}"
      end
    end)
  end

  # `x-amz-meta-*` headers are built from a map of string keys; callers hand us the
  # keyword/tuple lists that ExAws accepted.
  defp normalize_input("Metadata", value) when is_map(value), do: stringify_keys(value)
  defp normalize_input("Metadata", value) when is_list(value), do: stringify_keys(value)
  defp normalize_input(_name, value), do: value

  defp stringify_keys(pairs),
    do: Map.new(pairs, fn {key, value} -> {to_string(key), to_string(value)} end)

  # Only options aws-elixir passes through to the HTTP client, so callers can set
  # per-request timeouts on slow multipart operations.
  defp request_opts(opts),
    do: Keyword.take(opts, [:receive_timeout, :request_timeout, :pool_timeout])

  defp presign_options(client, opts) do
    [
      # S3 presigned URLs are unsigned-payload by definition.
      {:body_digest, "UNSIGNED-PAYLOAD"},
      {:ttl, Keyword.get(opts, :expires_in, @default_expires_in)}
    ]
    |> maybe_put(:session_token, client.session_token)
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: [{key, value} | opts]

  defp copy_source(bucket, key), do: "/" <> bucket <> "/" <> object_key(key)

  @doc """
  Normalize an object key the way ExAws's `normalize_path` did: collapse runs of
  slashes and drop any leading one.

  Meadow passes keys straight from `URI.parse(location).path`, which keeps its leading
  slash, and its existing objects were written under the collapsed form. aws-elixir
  interpolates the key into the path verbatim, so without this a key of `/a/b` would
  address `//a/b` — a different object.
  """
  def object_key(key) do
    key
    |> to_string()
    |> String.replace(~r"/{2,}", "/")
    |> String.trim_leading("/")
  end

  defp body(%{"Body" => body}), do: body
  defp body(body) when is_binary(body), do: body
  defp body(_), do: nil

  defp to_integer(nil), do: nil
  defp to_integer(value) when is_integer(value), do: value

  defp to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, _} -> integer
      :error -> nil
    end
  end

  defp unquote_etag(nil), do: nil
  defp unquote_etag(etag), do: String.replace(etag, ~s("), "")

  defp unwrap_bang(:ok), do: :ok
  defp unwrap_bang({:ok, value}), do: value

  defp unwrap_bang({:error, reason}),
    do: raise(Meadow.AWS.Error, message: "S3 request failed: #{inspect(reason)}")
end
