defmodule Meadow.Utils.ChangesetErrorsTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.ControlledTerms
  alias Meadow.Data.Schemas.Work
  alias Meadow.Utils.ChangesetErrors

  setup do
    ControlledTerms.fetch("unknown:nb2015010626")

    invalid_attrs = %{
      accession_number: "",
      administrative_metadata: %{
        preservation_level: %{id: "nope", scheme: "preservation_level"}
      },
      descriptive_metadata: %{
        contributor: [
          %{
            term: "missing_id_authority:123",
            role: %{
              id: "nop",
              scheme: "marc_relator"
            }
          }
        ],
        date_created: ["1899", "bad_date"],
        genre: [
          %{term: "wrong"},
          %{term: "http://id.loc.gov/authorities/names/nb2015010626"}
        ],
        subject: [
          %{
            term: "http://id.loc.gov/authorities/names/nb2015010626",
            role: %{
              id: "wrong_coded_term_id",
              scheme: "subject_role"
            }
          }
        ]
      }
    }

    changeset = Work.changeset(%Work{}, invalid_attrs)
    {:ok, %{changeset: changeset}}
  end

  test "extracts errors into a detailed structure", %{changeset: changeset} do
    assert ChangesetErrors.error_details(changeset) == %{
             accession_number: [%{error: "can't be blank", value: ""}],
             administrative_metadata: %{
               preservation_level: [
                 %{error: "is an invalid coded term for scheme PRESERVATION_LEVEL", value: "nope"}
               ]
             },
             descriptive_metadata: %{
               contributor: [
                 %{
                   term: [%{error: "is an unknown identifier", value: "missing_id_authority:123"}],
                   role: [
                     %{error: "is an invalid coded term for scheme MARC_RELATOR", value: "nop"}
                   ]
                 }
               ],
               date_created: [%{error: "is invalid", value: "[\"1899\", \"bad_date\"]"}],
               genre: [%{term: [%{error: "is from an unknown authority", value: "wrong"}]}, %{}],
               subject: [
                 %{
                   role: [
                     %{
                       error: "is an invalid coded term for scheme SUBJECT_ROLE",
                       value: "wrong_coded_term_id"
                     }
                   ]
                 }
               ]
             }
           }

    # NOTE: The test for date_created not the desired behavior. Each entry in the
    # array should validate separately the way embeds_many fields do. THe correct
    # expected value would be":
    # date_created: [%{}, %{edtf: %{error: "is invalid", value: "bad_date"}}]
  end

  def assert_all_equal(a, b) when is_list(a), do: MapSet.new(a) == MapSet.new(b)
  def assert_all_equal(a, b), do: a == b

  test "formats errors for human readability", %{changeset: changeset} do
    fields_to_flatten = [:administrative_metadata, :descriptive_metadata]

    actual = ChangesetErrors.humanize_errors(changeset, flatten: fields_to_flatten)

    expected = %{
      "accession_number" => "can't be blank",
      "contributor" => [
        "nop is an invalid coded term for scheme MARC_RELATOR",
        "missing_id_authority:123 is an unknown identifier"
      ],
      "date_created" => "[\"1899\", \"bad_date\"] is invalid",
      "genre#1" => ["wrong is from an unknown authority"],
      "preservation_level" => "nope is an invalid coded term for scheme PRESERVATION_LEVEL",
      "subject" => ["wrong_coded_term_id is an invalid coded term for scheme SUBJECT_ROLE"]
    }

    for {k, actual_v} <- actual do
      with expected_v <- Map.get(expected, k) do
        assert_all_equal(expected_v, actual_v)
      end
    end

    for {k, _} <- expected do
      assert Map.has_key?(actual, k)
    end

    # NOTE: The test for date_created not the desired behavior. Each entry in the
    # array should validate separately the way embeds_many fields do. THe correct
    # expected value would be":
    # "date_created#2" => "bad_date is invalid"
  end

  test "ignores nils" do
    assert Work.changeset(%Work{}, %{accession_number: nil})
           |> ChangesetErrors.humanize_errors()
           |> Map.get("accession_number") == "can't be blank"
  end

  test "ignores empty lists" do
    assert %{contributor: [%{error: "is empty", value: []}]}
           |> ChangesetErrors.humanize_errors()
           |> Map.get("contributor") == "is empty"
  end

  test "formats binary arrays for human readability" do
    assert %{"accession_number" => ["is missing"], "extra_field" => ["is unknown"]}
           |> ChangesetErrors.humanize_errors() ==
             %{"accession_number" => "is missing", "extra_field" => "is unknown"}
  end

  test "handles changesets without errors" do
    valid_attrs = %{
      accession_number: "12345",
      descriptive_metadata: %{title: "Test"}
    }

    changeset = Work.changeset(%Work{}, valid_attrs)

    assert ChangesetErrors.error_details(changeset) == %{}
  end
end
