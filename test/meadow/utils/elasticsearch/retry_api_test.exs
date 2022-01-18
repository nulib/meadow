defmodule Meadow.Utils.Elasticsearch.RetryAPITest do
  use ExUnit.Case

  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.Utils.Elasticsearch.RetryAPI

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
end
