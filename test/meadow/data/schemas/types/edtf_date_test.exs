defmodule Meadow.Data.Types.EDTF.DateTest do
  @moduledoc false
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Types.EDTFDate

  @edtf_db_type %{
    edtf: "1975-07-01",
    humanized: "July 1, 1975"
  }

  describe "Meadow.Data.Types.EDTFDate" do
    test "cast function" do
      assert {:ok, @edtf_db_type} == EDTFDate.cast(@edtf_db_type)
      assert EDTFDate.cast(1234) == {:error, [message: "Invalid edtf type"]}

      assert EDTFDate.cast("1975-07-01") ==
               {:ok, %{edtf: "1975-07-01", humanized: "July 1, 1975"}}
    end

    test "dump function" do
      assert EDTFDate.dump(@edtf_db_type) == {:ok, @edtf_db_type}
      assert EDTFDate.dump(134_524) == :error
    end

    test "load function" do
      assert EDTFDate.load(@edtf_db_type) == {:ok, @edtf_db_type}

      assert EDTFDate.load(1234) == {:error, [message: "Invalid edtf type"]}
    end
  end
end
