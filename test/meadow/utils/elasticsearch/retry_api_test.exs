defmodule Meadow.Utils.Elasticsearch.RetryAPITest do
  use Honeybadger.Case
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work
  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.Repo
  alias Meadow.Utils.Elasticsearch.RetryAPI

  import ExUnit.CaptureLog

  @too_many_fields_error ~r/Limit of total fields \[1500\] in index \[meadow-\d+\] has been exceeded/

  def current_api do
    Application.get_env(:meadow, Cluster) |> Keyword.get(:api)
  end

  describe "configure/0" do
    setup do
      with config <- Application.get_env(:meadow, Cluster) do
        Application.put_env(:meadow, Cluster, Keyword.put(config, :api, Elasticsearch.API.HTTP))

        :code.delete(Elasticsearch.API.HTTP.Retriable)
        :code.purge(Elasticsearch.API.HTTP.Retriable)

        on_exit(fn -> Application.put_env(:meadow, Cluster, config) end)
      end
    end

    test "reconfigures Elasticsearch with a retriable API" do
      assert current_api() == Elasticsearch.API.HTTP
      RetryAPI.configure()
      assert current_api() == Elasticsearch.API.HTTP.Retriable
    end

    test "does not create a retriable API if the configured API is already retriable" do
      assert current_api() == Elasticsearch.API.HTTP
      RetryAPI.configure()
      assert current_api() == Elasticsearch.API.HTTP.Retriable
      RetryAPI.configure()
      assert current_api() == Elasticsearch.API.HTTP.Retriable
      assert current_api() != Elasticsearch.API.HTTP.Retriable.Retriable
    end
  end

  describe "error reporting" do
    setup do
      {:ok, _} = Honeybadger.API.start(self())

      on_exit(&Honeybadger.API.stop/0)

      field_spam = 1..1500 |> Enum.map(&{"field_#{&1}", &1}) |> Enum.into(%{})

      index_doc =
        work_with_file_sets_fixture(1)
        |> Repo.preload(Work.required_index_preloads())
        |> Elasticsearch.Document.encode()
        |> put_in([:fileSets, Access.at(0), :extractedMetadata, "tooMuchData"], field_spam)

      {:ok, %{index_doc: index_doc}}
    end

    test "reports errors to Honeybadger", %{index_doc: index_doc} do
      restart_with_config(exclude_envs: [])

      log =
        capture_log(fn ->
          response =
            Elasticsearch.post(
              Meadow.ElasticsearchCluster,
              "/meadow/_doc/#{index_doc["id"]}",
              index_doc
            )

          assert {:error, {:ok, %HTTPoison.Response{body: body}}} = response
          assert %{"error" => %{"reason" => reason}} = body
          assert @too_many_fields_error |> Regex.match?(reason)
        end)

      assert Regex.scan(~r"Unexpected response from Elixir.Elasticsearch.API.HTTP.request/5", log)
             |> List.flatten()
             |> length() == 4

      assert_receive {:api_request, report}, 2500

      assert %{
               "error" => %{
                 "class" => "HTTPoison.Error",
                 "message" => message
               },
               "request" => %{"context" => context}
             } = report

      assert @too_many_fields_error |> Regex.match?(message)
      assert context |> Map.get("data") |> is_map()
      assert context |> Map.get("notifier") |> String.ends_with?(".Retriable")
    end
  end
end
