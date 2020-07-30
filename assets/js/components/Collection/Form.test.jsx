import React from "react";
import CollectionForm from "./Form";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { waitFor } from "@testing-library/react";
import { collectionMock } from "./collection.gql.mock";

function setupMatchTests() {
  return renderWithRouterApollo(<CollectionForm />, {
    route: "/collection/form",
  });
}

it("displays the collection form", () => {
  const { getByTestId, debug } = setupMatchTests();
  expect(getByTestId("collection-form")).toBeInTheDocument();
});

it("displays all form fields", () => {
  const { queryByTestId } = setupMatchTests();
  expect(queryByTestId("input-collection-title")).toBeInTheDocument();
  expect(queryByTestId("input-collection-type")).toBeInTheDocument();
  expect(queryByTestId("checkbox-featured")).toBeInTheDocument();
  expect(queryByTestId("textarea-description")).toBeInTheDocument();
  expect(queryByTestId("input-finding-aid-url")).toBeInTheDocument();
  expect(queryByTestId("input-admin-email")).toBeInTheDocument();
  expect(queryByTestId("input-keywords")).toBeInTheDocument();
});

it("renders no initial form values when creating a collection", async () => {
  const { getByTestId, debug } = renderWithRouterApollo(<CollectionForm />, {
    route: "/collection/form",
  });

  await waitFor(() => {
    expect(getByTestId("input-collection-title")).toHaveValue("");
    expect(getByTestId("textarea-description")).toHaveValue("");
    expect(getByTestId("input-finding-aid-url")).toHaveValue("");
    expect(getByTestId("input-admin-email")).toHaveValue("");
    expect(getByTestId("input-keywords")).toHaveValue("");
  });
});

it("renders existing collection values in the form when editing a form", async () => {
  const { getByTestId, debug } = renderWithRouterApollo(
    <CollectionForm collection={collectionMock} />,
    {}
  );
  await waitFor(() => {
    expect(getByTestId("input-collection-title")).toHaveValue(
      "Great collection"
    );
    expect(getByTestId("textarea-description")).toHaveValue(
      "Collection description lorem ipsum"
    );
    expect(getByTestId("input-finding-aid-url")).toHaveValue(
      "https://northwestern.edu"
    );

    expect(getByTestId("input-admin-email")).toHaveValue("admin@nu.com");
    expect(getByTestId("input-keywords")).toHaveValue("yo,foo,bar,work,hey");
  });
});

//TODO: How to test this form with route changes, using useHistory() hook
//TODO: Follow assets/js/screens/Project/Project.test.js for examples
