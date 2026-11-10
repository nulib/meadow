defmodule Meadow.Search.ConfigTest do
  use ExUnit.Case

  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Search.Config, as: SearchConfig

  describe "settings_for/2" do
    test "does not use an ingest pipeline; embeddings arrive in the document" do
      settings = SearchConfig.settings_for(Work, 2)
      refute get_in(settings, ["settings", "default_pipeline"])
    end

    test "sizes the embedding field to the embedding model" do
      settings = SearchConfig.settings_for(Work, 2)

      assert %{"type" => "knn_vector", "dimension" => 768} =
               get_in(settings, ["mappings", "properties", "embedding"])
    end

    test "sizes the file set embedding field the same way" do
      settings = SearchConfig.settings_for(FileSet, 2)

      assert get_in(settings, ["settings", "index", "knn"]) == true

      assert %{"type" => "knn_vector", "dimension" => 768} =
               get_in(settings, ["mappings", "properties", "embedding"])
    end

    test "leaves mappings without an embedding field alone" do
      settings = SearchConfig.settings_for(Collection, 2)
      refute get_in(settings, ["mappings", "properties", "embedding"])
    end
  end

  describe "search_pipeline_for/2" do
    test "names the hybrid search pipeline for works only" do
      assert SearchConfig.search_pipeline_for(Work, 2) =~ "dc-v2-work-pipeline"
      refute SearchConfig.search_pipeline_for(Collection, 2)
    end
  end
end
