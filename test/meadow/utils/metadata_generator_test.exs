defmodule Meadow.Utils.MetadataGeneratorTest do
  use ExUnit.Case
  use Meadow.DataCase

  alias Meadow.Utils.MetadataGenerator

  describe "Meadow.Utils.MetadataGenerator" do
    test "`generate_descriptive_metadata_for/1`" do
      work = work_fixture()

      assert Enum.empty?(work.descriptive_metadata.creator)

      MetadataGenerator.prewarm_cache()
      [{:ok, work}] = MetadataGenerator.generate_descriptive_metadata_for([work])

      refute Enum.empty?(work.descriptive_metadata.creator)
    end
  end
end
