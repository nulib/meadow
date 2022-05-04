defmodule Meadow.ElasticsearchCluster do
  @moduledoc """
  Defines the Elasticsearch cluster
  """
  use Elasticsearch.Cluster, otp_app: :meadow
end
