defmodule Meadow.Utils.Ecto.SchemaTest do
  use ExUnit.Case, async: true

  alias Meadow.Data.Schemas.{Work, FileSet}
  alias Meadow.Utils.Ecto.Schema

  describe "unroll(Work)" do
    setup do
      {:ok, subject: Schema.unroll(Work)}
    end

    test "returns a map", %{subject: subject} do
      assert is_map(subject)
    end

    test "handles UUID fields", %{subject: subject} do
      assert subject.id == "UUID"
    end

    test "handles top-level CodedTerm fields with correct scheme", %{subject: subject} do
      assert subject.visibility == %{
        id: "(valid id for scheme `visibility`)",
        label: "(valid label for scheme `visibility`)",
        scheme: "visibility"
      }
    end

    test "handles DateTime fields", %{subject: subject} do
      assert subject.inserted_at == "utc_datetime (microsecond precision)"
    end

    test "handles embedded schemas", %{subject: subject} do
      assert is_map(subject.administrative_metadata)
      assert is_map(subject.descriptive_metadata)
    end

    test "handles simple string fields in embedded schemas", %{subject: subject} do
      assert subject.descriptive_metadata.title == "string"
    end

    test "handles CodedTerm fields with correct scheme in embedded schemas", %{subject: subject} do
      assert subject.descriptive_metadata.license == %{
        id: "(valid id for scheme `license`)",
        label: "(valid label for scheme `license`)",
        scheme: "license"
      }
    end

    test "handles single- and multi-value fields in embedded schemas", %{subject: subject} do
      assert subject.descriptive_metadata.title == "string"
      assert subject.descriptive_metadata.alternate_title == ["string"]
    end

    test "handles multi-valued controlled term without role in embedded schemas", %{subject: subject} do
      assert subject.descriptive_metadata.language == [%{term: %{id: "URI", label: "string"}, role: nil}]
    end

    test "handles multi-valued controlled term with role in embedded schemas", %{subject: subject} do
      assert subject.descriptive_metadata.subject == [
        %{
          term: %{id: "URI", label: "string"},
          role: %{
            id: "(valid id for scheme `subject_role`)",
            label: "(valid label for scheme `subject_role`)",
            scheme: "subject_role"
          }
        }
      ]
    end

    test "handles EDTF date fields in embedded schemas", %{subject: subject} do
      assert subject.descriptive_metadata.date_created == ["valid EDTF date string"]
    end
  end

  describe "unroll(Work) with read_only option" do
    test "omits specified fields at the top level" do
      result = Schema.unroll(Work, read_only: [:administrative_metadata, :visibility])
      Map.get(result, :administrative_metadata)
      |> Enum.each(fn {_, value} ->
        assert value == "READ_ONLY"
      end)
      assert Map.get(result, :visibility) == "READ_ONLY"
      assert Map.has_key?(result, :id)
    end

    test "omits specified fields in embedded schemas" do
      result = Schema.unroll(Work, read_only: [descriptive_metadata: [:license]])
      assert Map.has_key?(result, :descriptive_metadata)
      assert Map.get(result.descriptive_metadata, :license) == "READ_ONLY"
      assert Map.has_key?(result.descriptive_metadata, :title)
    end
  end

  describe "unroll(FileSet)" do
    setup do
      {:ok, subject: Schema.unroll(FileSet)}
    end

    test "handles embedded schemas in FileSet", %{subject: subject} do
      assert is_map(subject)
      assert is_map(subject.core_metadata)
      assert subject.core_metadata.original_filename == "string"
    end
  end
end
