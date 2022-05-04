defmodule Meadow.Data.CSV.UtilsTest do
  use ExUnit.Case
  import Meadow.Data.CSV.Utils

  @field_with_literal_pipes ["There", "Are", "Three | Values"]
  @combined_with_literal_pipes "There | Are | Three \\| Values"
  @field_without_literal_pipes ["There", "Are", "Four", "Values"]
  @combined_without_literal_pipes "There | Are | Four | Values"

  test "combine_multivalued_field/1" do
    assert combine_multivalued_field(@field_with_literal_pipes) ==
             @combined_with_literal_pipes

    assert combine_multivalued_field(@field_without_literal_pipes) ==
             @combined_without_literal_pipes
  end

  test "split_multivalued_field/1" do
    assert split_multivalued_field(@combined_with_literal_pipes) ==
             @field_with_literal_pipes

    assert split_multivalued_field(@combined_without_literal_pipes) ==
             @field_without_literal_pipes
  end
end
