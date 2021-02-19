import React from "react";
import ScreensCollectionForm from "./Form";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor } from "@testing-library/react";
import { getCollectionMock } from "../../components/Collection/collection.gql.mock";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

const mocks = [getCollectionMock, getCurrentUserMock, ...allCodeListMocks];

function setupTests() {
  return renderWithRouterApollo(
    <AuthProvider>
      <Route path="/collection/form/:id" component={ScreensCollectionForm} />
    </AuthProvider>,
    {
      mocks,
      route: "/collection/form/7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
    }
  );
}

it("renders without crashing", async () => {
  const { container, queryByTestId } = setupTests();

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
  const { findByTestId } = setupTests();
  expect(await findByTestId("breadcrumbs"));
});

it("renders no initial form values when creating a collection", async () => {
  const { getByTestId } = renderWithRouterApollo(
    <AuthProvider>
      <Route path="/collection/form/" component={ScreensCollectionForm} />
    </AuthProvider>,
    {
      mocks: [getCurrentUserMock, ...allCodeListMocks],
      route: "/collection/form/",
    }
  );

  await waitFor(() => {
    expect(getByTestId("input-collection-title")).toHaveValue("");
    expect(getByTestId("textarea-description")).toHaveValue("");
    expect(getByTestId("input-finding-aid-url")).toHaveValue("");
    expect(getByTestId("input-admin-email")).toHaveValue("");
    expect(getByTestId("input-keywords")).toHaveValue("");
  });
});

it("renders existing collection values in the form when editing a form", async () => {
  const { getByTestId } = setupTests();

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
