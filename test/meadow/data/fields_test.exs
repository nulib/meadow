defmodule Meadow.Data.FieldsTest do
  use Meadow.DataCase

  alias Meadow.Data.Fields

  describe "queries" do
    test "describe/0 returns all fields" do
      assert length(Fields.describe()) > 1
    end

    test "describe/1 fetches the field info by id" do
      subject = Fields.describe("subject")
      assert subject.label == "Subject"
    end
  end
end
