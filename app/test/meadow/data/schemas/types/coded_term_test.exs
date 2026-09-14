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

  # A field declared without a scheme (legacy jsonb embed) stores an {id, scheme} map
  @map_type {:parameterized, {CodedTerm, CodedTerm.init([])}}
  # A field declared with a scheme stores the bare id
  @id_type {:parameterized, {CodedTerm, CodedTerm.init(scheme: "rights_statement")}}

  describe "without a fixed scheme" do
    test "cast function" do
      assert {:ok, @coded_term_custom_type} == Ecto.Type.cast(@map_type, @coded_term_db_type)
      assert Ecto.Type.cast(@map_type, 1234) == {:error, [message: "is invalid"]}

      assert {:error, [message: "is an invalid coded term for scheme RIGHTS_STATEMENT"]} ==
               Ecto.Type.cast(@map_type, %{id: "totallywrong", scheme: "rights_statement"})

      assert {:error, [message: "is an invalid coded term for scheme LICENSE"]} ==
               Ecto.Type.cast(@map_type, %{
                 id: "http://rightsstatements.org/vocab/CNE/1.0/",
                 scheme: "license"
               })
    end

    test "dump function" do
      assert Ecto.Type.dump(@map_type, @coded_term_custom_type) == {:ok, @coded_term_db_type}
      assert Ecto.Type.dump(@map_type, 134_524) == :error
    end

    test "load function" do
      assert Ecto.Type.load(@map_type, @coded_term_db_type) == {:ok, @coded_term_custom_type}
      assert Ecto.Type.load(@map_type, 1234) == {:error, [message: "is invalid"]}
    end
  end

  describe "with a fixed scheme" do
    test "storage type is a string" do
      assert Ecto.Type.type(@id_type) == :string
      assert Ecto.Type.type(@map_type) == :map
    end

    test "cast accepts an id, an {id} map, or a matching {id, scheme} map" do
      for input <- [
            "http://rightsstatements.org/vocab/CNE/1.0/",
            %{id: "http://rightsstatements.org/vocab/CNE/1.0/"},
            %{"id" => "http://rightsstatements.org/vocab/CNE/1.0/"},
            @coded_term_db_type,
            %{id: "http://rightsstatements.org/vocab/CNE/1.0/", scheme: "RIGHTS_STATEMENT"}
          ] do
        assert {:ok, @coded_term_custom_type} == Ecto.Type.cast(@id_type, input)
      end

      assert {:error, [message: "has scheme license but field requires rights_statement"]} ==
               Ecto.Type.cast(@id_type, %{
                 id: "http://rightsstatements.org/vocab/CNE/1.0/",
                 scheme: "license"
               })

      assert {:error, [message: "is an invalid coded term for scheme RIGHTS_STATEMENT"]} ==
               Ecto.Type.cast(@id_type, "totallywrong")
    end

    test "dump writes the bare id and load restores the full term" do
      assert Ecto.Type.dump(@id_type, @coded_term_custom_type) ==
               {:ok, "http://rightsstatements.org/vocab/CNE/1.0/"}

      assert Ecto.Type.dump(@id_type, nil) == {:ok, nil}

      assert Ecto.Type.load(@id_type, "http://rightsstatements.org/vocab/CNE/1.0/") ==
               {:ok, @coded_term_custom_type}

      assert Ecto.Type.load(@id_type, nil) == {:ok, nil}
    end
  end

  describe "schema introspection helpers" do
    test "coded_term_type?/1 and scheme_for/1" do
      assert CodedTerm.coded_term_type?(@id_type)
      assert CodedTerm.coded_term_type?(@map_type)
      refute CodedTerm.coded_term_type?(:string)
      assert CodedTerm.scheme_for(@id_type) == "rights_statement"
      assert CodedTerm.scheme_for(@map_type) == nil
    end
  end
end
