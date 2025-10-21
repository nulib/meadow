defmodule NUL.AuthorityTest do
  use Meadow.DataCase

  alias NUL.{Authority, AuthorityRecords}

  setup do
    authority_records = [
      AuthorityRecords.create_authority_record!(%{
        label: "Ver Steeg, Clarence L.",
        hint: "(The Legend)"
      }),
      AuthorityRecords.create_authority_record!(%{
        label: "Ver Steeg, Dorothy A."
      }),
      AuthorityRecords.create_authority_record!(%{
        label: "steering committee"
      }),
      AuthorityRecords.create_authority_record!(%{
        label: "Netsch, Walter A.",
        hint: "Also a Legend"
      }),
      AuthorityRecords.create_authority_record!(%{
        label: "Legendary label"
      })
    ]

    {:ok, authority_record: List.first(authority_records)}
  end

  test "implements the Authoritex behaviour" do
    assert Authority.__info__(:attributes)
           |> get_in([:behaviour])
           |> Enum.member?(Authoritex)
  end

  test "can_resolve?/1" do
    assert Authority.can_resolve?("info:nul")
    refute Authority.can_resolve?("info:fake/uri")
  end

  describe "introspection" do
    test "code/0" do
      assert Authority.code() == "nul-authority"
    end

    test "description/0" do
      assert Authority.description() == "Northwestern University Libraries local authority"
    end
  end

  describe "fetch/1" do
    test "success", %{authority_record: authority_record} do
      assert {:ok,
              %{
                label: "Ver Steeg, Clarence L.",
                qualified_label: "Ver Steeg, Clarence L. (The Legend)",
                hint: "(The Legend)",
                variants: []
              }} = Authority.fetch(authority_record.id)
    end

    test "failure" do
      assert {:error, 404} = Authority.fetch("info:nul/wrong")
    end
  end

  describe "search/2" do
    test "results" do
      with {:ok, results} <- Authority.search("Ver Steeg") do
        assert length(results) == 2
      end

      with {:ok, results} <-
             Authority.search("Ver Steeg", 1) do
        assert length(results) == 1
      end

      with {:ok, results} <- Authority.search("stee") do
        assert Enum.all?(results, fn result -> String.match?(result.label, ~r/stee/i) end)
      end
    end

    test "includes results for both labels and hints" do
      with {:ok, results} <- Authority.search("Legend") do
        assert length(results) == 3
      end
    end

    test "no results" do
      assert {:ok, []} = Authority.search("M1551ng")
    end

    test "respects limit parameter" do
      # Search for "Legend" matches 3 records (2 in hint, 1 in label)
      assert {:ok, results} = Authority.search("Legend", 1)
      assert length(results) == 1

      assert {:ok, results} = Authority.search("Legend", 2)
      assert length(results) == 2

      assert {:ok, results} = Authority.search("Legend", 3)
      assert length(results) == 3

      assert {:ok, results} = Authority.search("Legend", 100)
      assert length(results) == 3
    end
  end
end
