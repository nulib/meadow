defmodule Meadow.Data.CodedTermsTest do
  use Meadow.DataCase
  alias Meadow.Data.CodedTerms
  import Assertions

  @schemes [
    "authority",
    "file_set_role",
    "library_unit",
    "license",
    "marc_relator",
    "note_type",
    "preservation_level",
    "published",
    "related_url",
    "rights_statement",
    "status",
    "subject_role",
    "visibility",
    "work_type"
  ]

  describe "CodedTerms context" do
    test "lists schemes" do
      assert_lists_equal(@schemes, CodedTerms.list_schemes())
    end

    test "lists terms within a scheme" do
      with results <- CodedTerms.list_coded_terms("work_type") do
        assert_lists_equal(results |> Enum.map(& &1.id), ["AUDIO", "IMAGE", "VIDEO"])

        assert_lists_equal(results |> Enum.map(& &1.label), [
          "Audio",
          "Image",
          "Video"
        ])
      end
    end

    test "returns an empty term list for an unknown scheme" do
      assert CodedTerms.list_coded_terms("nope_not_here") == []
    end

    test "fetches a term by scheme and id" do
      with {{:ok, _}, result} <- CodedTerms.get_coded_term("cmp", "marc_relator") do
        assert result.id == "cmp"
        assert result.label == "Composer"
      end
    end

    test "returns nil for an unknown id" do
      assert CodedTerms.get_coded_term("zzz", "marc_relator") |> is_nil()
    end

    test "returns nil for an unknown scheme" do
      assert CodedTerms.get_coded_term("cmp", "nope_still_not_here") |> is_nil()
    end
  end

  describe "get_coded_term/2" do
    test "cache miss" do
      assert {{:ok, :db}, _term} = CodedTerms.get_coded_term("cpl", "marc_relator")
    end

    test "cache hit" do
      assert {{:ok, :db}, _term} = CodedTerms.get_coded_term("ive", "marc_relator")
      assert {{:ok, :memory}, _term} = CodedTerms.get_coded_term("ive", "marc_relator")
    end

    test "db miss (invalid coded term)" do
      assert nil == CodedTerms.get_coded_term("ivdde", "marc_relator")
    end
  end
end
