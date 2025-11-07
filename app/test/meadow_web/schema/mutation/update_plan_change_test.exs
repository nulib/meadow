defmodule MeadowWeb.Schema.Mutation.UpdatePlanChangeTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdatePlanChange.gql")

  test "should update add field in plan change" do
    plan_change = plan_change_fixture()

    new_add = ~s({"descriptive_metadata":{"title":"New Title","description":["New description"]}})

    result =
      query_gql(
        variables: %{"id" => plan_change.id, "add" => new_add},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanChange"])
    assert response["id"] == plan_change.id
    assert response["add"]["descriptive_metadata"]["title"] == "New Title"
    assert response["status"] == "PROPOSED"
  end

  test "should update replace field in plan change" do
    plan_change = plan_change_fixture()

    new_replace = ~s({"descriptive_metadata":{"description":["Replaced description"]}})

    result =
      query_gql(
        variables: %{"id" => plan_change.id, "replace" => new_replace},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanChange"])
    assert response["id"] == plan_change.id
    assert response["replace"]["descriptive_metadata"]["description"] == ["Replaced description"]
  end

  test "should update delete field in plan change" do
    plan_change = plan_change_fixture()

    new_delete = ~s({"descriptive_metadata":{"notes":["Note to delete"]}})

    result =
      query_gql(
        variables: %{"id" => plan_change.id, "delete" => new_delete},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanChange"])
    assert response["id"] == plan_change.id
    assert response["delete"]["descriptive_metadata"]["notes"] == ["Note to delete"]
  end

  test "should update multiple fields at once" do
    plan_change = plan_change_fixture()

    new_add = ~s({"descriptive_metadata":{"title":"New Title"}})
    new_replace = ~s({"descriptive_metadata":{"description":["Updated"]}})
    new_delete = ~s({"descriptive_metadata":{"notes":["Old note"]}})

    result =
      query_gql(
        variables: %{"id" => plan_change.id, "add" => new_add, "replace" => new_replace, "delete" => new_delete},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanChange"])
    assert response["id"] == plan_change.id
    assert response["add"]["descriptive_metadata"]["title"] == "New Title"
    assert response["replace"]["descriptive_metadata"]["description"] == ["Updated"]
    assert response["delete"]["descriptive_metadata"]["notes"] == ["Old note"]
  end

  test "should return error for non-existent plan change" do
    result =
      query_gql(
        variables: %{"id" => Ecto.UUID.generate(), "add" => ~s({})},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    error = List.first(get_in(query_data, [:errors]))
    assert error.message == "Plan change not found"
  end
end
