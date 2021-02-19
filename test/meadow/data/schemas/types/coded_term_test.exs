defmodule Meadow.Data.Types.CodedTermTest do
  @moduledoc false
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Types.CodedTerm

  @coded_term_db_type %{
    id: "http://rightsstatements.org/vocab/CNE/1.0/",
    scheme: "rights_statement"
  }

  @coded_term_custom_type %{
    id: "http://rightsstatements.org/vocab/CNE/1.0/",
    scheme: "rights_statement",
    label: "Copyright Not Evaluated"
  }

  describe "Meadow.Data.Types.CodedTerm" do
    test "cast function" do
      assert {:ok, @coded_term_custom_type} == CodedTerm.cast(@coded_term_db_type)
      assert CodedTerm.cast(1234) == {:error, [message: "is invalid"]}

      assert {:error, [message: "is an invalid coded term for scheme RIGHTS_STATEMENT"]} ==
               CodedTerm.cast(%{id: "totallywrong", scheme: "rights_statement"})

      assert {:error,
              [
                message: "is an invalid coded term for scheme LICENSE"
              ]} ==
               CodedTerm.cast(%{
                 id: "http://rightsstatements.org/vocab/CNE/1.0/",
                 scheme: "license"
               })
    end

    test "dump function" do
      assert CodedTerm.dump(@coded_term_custom_type) == {:ok, @coded_term_db_type}
      assert CodedTerm.dump(134_524) == :error
    end

    test "load function" do
      assert CodedTerm.load(@coded_term_db_type) == {:ok, @coded_term_custom_type}

      assert CodedTerm.load(1234) == {:error, [message: "is invalid"]}
    end
  end
end
