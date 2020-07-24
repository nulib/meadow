import React from "react";
import ScreensCollectionForm from "./Form";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor } from "@testing-library/react";
import { getCollectionMock } from "../../components/Collection/collection.gql.mock";
const mocks = [getCollectionMock];

function setupTests() {
  return renderWithRouterApollo(
    <Route path="/collection/form/:id" component={ScreensCollectionForm} />,
    {
      mocks,
      route: "/collection/form/7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
    }
  );
}

it("renders without crashing", async () => {
  const { container, queryByTestId } = setupTests();

  expect(queryByTestId("loading")).toBeInTheDocument();

  await waitFor(() => {
    expect(queryByTestId("loading")).not.toBeInTheDocument();
    expect(container).toBeTruthy();
  });
});

it("renders add collection title", async () => {
  const { getByTestId } = setupTests();

  await waitFor(() => {
    expect(getByTestId("collection-form-title")).toBeInTheDocument();
  });
});

it("renders breadcrumbs", async () => {
  const { getByTestId } = setupTests();

  await waitFor(() => {
    expect(getByTestId("breadcrumbs")).toBeInTheDocument();
  });
});

it("renders no initial form values when creating a collection", async () => {
  const { getByTestId } = renderWithRouterApollo(
    <Route path="/collection/form/" component={ScreensCollectionForm} />,
    {
      route: "/collection/form/",
    }
  );

  await waitFor(() => {
    expect(getByTestId("input-collection-name")).toHaveValue("");
    expect(getByTestId("textarea-description")).toHaveValue("");
    expect(getByTestId("input-finding-aid-url")).toHaveValue("");
    expect(getByTestId("input-admin-email")).toHaveValue("");
    expect(getByTestId("input-keywords")).toHaveValue("");
  });
});

it("renders existing collection values in the form when editing a form", async () => {
  const { getByTestId } = setupTests();

  await waitFor(() => {
    expect(getByTestId("input-collection-name")).toHaveValue(
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
