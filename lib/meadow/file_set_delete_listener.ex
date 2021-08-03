defmodule Meadow.FilesetDeleteListener do
  @moduledoc """
  Database notification listener to clean up file set assets after records are deleted
  """

  use GenServer

  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Utils.AWS

  use Meadow.Utils.Logging

  import Ecto.Query

  require Logger

  @message "file_sets_deleted"

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(initial_state) do
    Logger.info("#{__MODULE__}: Listening for delete notifications on 'file_sets'")
    Meadow.Repo.listen(@message)

    {:ok, initial_state}
  end

  def handle_info({:notification, _pid, _ref, @message, payload}, state) do
    with %{data: data} <- Jason.decode!(payload, keys: :atoms) do
      Enum.each(data, fn file_set_data ->
        clean_up!(file_set_data, state)
      end)
    end

    {:noreply, state}
  rescue
    exception ->
      Meadow.Error.report(exception, __MODULE__, __STACKTRACE__)
      reraise(exception, __STACKTRACE__)
  end

  @impl GenServer
  def handle_info({:ssl_closed, _msg}, state), do: {:noreply, state}

  defp clean_up!(file_set_data, state) do
    with_log_metadata(module: __MODULE__, id: file_set_data.id) do
      Logger.warn("Cleaning up assets for file set #{file_set_data.id}")

      file_set_data
      |> clean_derivatives!(state)
      |> clean_preservation_file!(state)

      with target <- Keyword.get(state, :notify) do
        if target |> is_pid(), do: send(target, {"cleaned", file_set_data.id})
      end
    end
  end

  defp clean_derivatives!(file_set_data, _state) do
    file_set_data.derivatives
    |> Enum.each(fn {type, location} ->
      clean_derivative!(type, location)
    end)

    file_set_data
  end

  defp clean_derivative!(:playlist, "s3://" <> _ = playlist) do
    with stream_base <- Path.dirname(playlist) <> "/" do
      Logger.warn("Removing streaming files from #{stream_base}")
      delete_s3_uri(stream_base, true)
    end
  end

  defp clean_derivative!(type, "s3://" <> _ = uri) do
    Logger.warn("Removing #{type} derivative at #{uri}")
    delete_s3_uri(uri)
  end

  defp clean_derivative!(_, _), do: :ok

  defp clean_preservation_file!(file_set_data, state) do
    with location <- file_set_data.location,
         repo <- Keyword.get(state, :repo, Meadow.Repo) do
      refs =
        from(f in FileSet,
          where:
            fragment("core_metadata ->> 'location' = ?", ^location) and
              f.id != ^file_set_data.id
        )
        |> repo.aggregate(:count)

      if refs == 0 do
        Logger.warn("Removing preservation file at #{location}")
        delete_s3_uri(location)
      else
        references = Inflex.Pluralize.inflect("reference", refs)
        Logger.warn("Leaving #{location} intact: #{refs} additional #{references}")
      end
    end

    file_set_data
  end

  defp delete_s3_uri(uri, recursive \\ false)

  defp delete_s3_uri(uri, true) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(uri) do
      case ExAws.S3.head_bucket(bucket) |> AWS.request() do
        {:error, {:http_error, 404, _}} ->
          :noop

        _ ->
          keys =
            ExAws.S3.list_objects(bucket, prefix: key)
            |> ExAws.stream!()
            |> Stream.map(& &1.key)

          ExAws.S3.delete_all_objects(bucket, keys)
          |> AWS.request()
      end
    end
  end

  defp delete_s3_uri(uri, false) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(uri) do
      ExAws.S3.delete_object(bucket, key)
      |> AWS.request()
    end
  end
end
