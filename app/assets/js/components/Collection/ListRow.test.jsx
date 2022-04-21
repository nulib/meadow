import React from "react";
import CollectionListRow from "./ListRow";
import { renderWithRouter } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("CollectionListRow component", () => {
  function setUpTests() {
    return renderWithRouter(<CollectionListRow collection={collectionMock} />);
  }
  it("renders the root element", async () => {
    const { findByTestId } = renderWithRouter(
      <CollectionListRow collection={collectionMock} />
    );
    expect(await findByTestId("collection-list-row"));
  });
});
