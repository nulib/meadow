import React from "react";
import CollectionListRow from "./ListRow";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { waitFor } from "@testing-library/dom";

describe("CollectionListRow component", () => {
  function setUpTests() {
    return renderWithRouterApollo(
      <AuthProvider>
        <CollectionListRow collection={collectionMock} />
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock],
      }
    );
  }
  it("renders the root element", async () => {
    const { getByTestId } = setUpTests();
    await waitFor(() => {
      expect(getByTestId("collection-list-row")).toBeInTheDocument();
    });
  });
});
