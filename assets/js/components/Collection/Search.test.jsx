import React from "react";
import CollectionSearch from "./Search";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { screen, waitFor } from "@testing-library/react";

function setupTests() {
  return;
}
describe("CollectionSearch component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <CollectionSearch collection={collectionMock} />
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock],
      }
    );
  });
  it("renders the root element", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("collection-search"));
    });
  });

  // TODO: All these tests seem to be testing elements not directly rendered in the CollectionSearch component.  They should be moved to their appropriate component.
  it("displays number of works", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("number-of-works").innerHTML).toBe(
        "2 results..."
      );
    });
  });

  it("displays work title", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("work-title-1id-23343432").innerHTML).toBe(
        "Title 1"
      );
    });
  });

  xit("displays default work title", () => {
    const { getByTestId, debug } = setupTests();
    expect(getByTestId("work-title-2is-234o24332-id").innerHTML).toBe(
      "Untitled"
    );
  });
});
