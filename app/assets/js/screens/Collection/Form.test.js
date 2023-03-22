import React from "react";
import { Route } from "react-router-dom";
import ScreensCollectionForm from "./Form";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { getCollectionMock } from "../../components/Collection/collection.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { waitFor } from "@testing-library/react";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [getCollectionMock, ...allCodeListMocks];

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
