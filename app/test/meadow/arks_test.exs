defmodule Meadow.ArksTest do
  use Meadow.DataCase

  alias Meadow.{Ark, Arks}
  alias Meadow.Ark.MockServer
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works

  describe "mint_ark/1" do
    @describetag visibility: "OPEN"
    setup %{work_type: work_type, visibility: visibility} do
      {:ok,
       work:
         work_fixture(%{
           work_type: %{id: work_type, scheme: "work_type"},
           visibility: %{id: visibility, scheme: "visibility"}
         })}
    end

    seed_values("coded_terms/work_type")
    |> Enum.each(fn %{id: work_type} ->
      @tag work_type: work_type
      test "mint_ark/1 mints an ark for #{work_type} work type", %{work: work} do
        assert {:ok, %{descriptive_metadata: %{ark: ark}}} = Arks.mint_ark(work)
        assert is_binary(ark)
      end

      @tag work_type: work_type
      test "mint_ark!/1 mints an ark for #{work_type} work type", %{work: work} do
        assert Arks.mint_ark!(work)
      end
    end)

    @tag work_type: "IMAGE"
    test "mint_ark/1 does not mint a new ark for a work that already has an ark", %{work: work} do
      assert {:ok, %Work{descriptive_metadata: %{ark: ark}} = work} = Arks.mint_ark(work)
      assert {:noop, %Work{descriptive_metadata: %{ark: ^ark}}} = Arks.mint_ark(work)
    end
  end

  describe "ark status" do
    @describetag published: false

    setup do
      MockServer.send_to(self())
    end

    setup %{published: published, visibility: visibility} do
      work =
        work_fixture(%{
          published: published,
          visibility: %{id: visibility, scheme: "visibility"}
        })
        |> Arks.mint_ark!()

      {:ok, work: work}
    end

    @tag visibility: "OPEN", published: false
    test "mints an ark for an unpublished/open work", %{work: work} do
      assert {:ok, %Ark{status: "reserved"}} = Arks.existing_ark(work)
    end

    @tag visibility: "AUTHENTICATED", published: false
    test "mints an ark for an unpublished/authenticated work", %{work: work} do
      assert {:ok, %Ark{status: "reserved"}} = Arks.existing_ark(work)
    end

    @tag visibility: "RESTRICTED", published: false
    test "mints an ark for an unpublished/restricted work", %{work: work} do
      assert {:ok, %Ark{status: "reserved"}} = Arks.existing_ark(work)
    end

    @tag visibility: "OPEN", published: true
    test "mints an ark for a published/open work", %{work: work} do
      assert {:ok, %Ark{status: "public"}} = Arks.existing_ark(work)
    end

    @tag visibility: "AUTHENTICATED", published: true
    test "mints an ark for a published/authenticated work", %{work: work} do
      assert {:ok, %Ark{status: "public"}} = Arks.existing_ark(work)
    end

    @tag visibility: "RESTRICTED", published: true
    test "mints an ark for a published/restricted work", %{work: work} do
      assert {:ok, %Ark{status: "unavailable | restricted"}} = Arks.existing_ark(work)
    end

    @tag visibility: "OPEN"
    test "correctly transitions from reserved to public when published", %{work: work} do
      assert {:ok, %Ark{status: "reserved"}} = Arks.existing_ark(work)

      work
      |> Works.update_work!(%{published: true})
      |> Arks.update_ark_metadata()

      assert {:ok, %Ark{status: "public"}} = Arks.existing_ark(work)
    end

    @tag visibility: "RESTRICTED"
    test "correctly transitions from reserved to unavailable when published", %{work: work} do
      assert_received(%{message: {:post, :body, anvl}, at: reserved_time})
      assert String.contains?(anvl, "_status: reserved")
      assert {:ok, %Ark{status: "reserved"}} = Arks.existing_ark(work)

      work
      |> Works.update_work!(%{published: true})
      |> Arks.update_ark_metadata()

      assert_received(%{message: {:post, :body, anvl}, at: public_time})
      assert String.contains?(anvl, "_status: public")

      assert_received(%{message: {:post, :body, anvl}, at: unavailable_time})
      assert String.contains?(anvl, "_status: unavailable | restricted")

      assert reserved_time < public_time
      assert public_time < unavailable_time

      assert {:ok, %Ark{status: "unavailable | restricted"}} = Arks.existing_ark(work)
    end
  end
end
