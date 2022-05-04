import React from "react";
import Collection from "./Collection";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { waitFor } from "@testing-library/dom";
import { screen } from "@testing-library/react";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("Collection Test", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <CodeListProvider>
        <Collection collection={collectionMock} />
      </CodeListProvider>,
      {
        mocks: [...allCodeListMocks],
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
