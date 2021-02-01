import React from "react";
import Collection from "./Collection";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { waitFor } from "@testing-library/dom";
import { screen } from "@testing-library/react";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

describe("Collection Test", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <CodeListProvider>
        <AuthProvider>
          <Collection collection={collectionMock} />
        </AuthProvider>
      </CodeListProvider>,
      {
        mocks: [getCurrentUserMock, ...allCodeListMocks],
      }
    );
  });

  it("renders Collection component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("collection"));
    });
  });

  it("renders collection properties", async () => {
    await waitFor(() => {
      expect(screen.getByText("admin@nu.com"));
      expect(screen.getByText("Collection description lorem ipsum"));
    });
  });
});
