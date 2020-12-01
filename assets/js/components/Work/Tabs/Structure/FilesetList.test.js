import React from "react";
import WorkTabsStructureFilesetList from "./FilesetList";
import { render, screen, waitFor } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import {
  withReactBeautifulDND,
  renderWithRouterApollo,
} from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { async } from "openseadragon-react-viewer";

describe("WorkTabsStructureFilesets components", () => {
  it("renders a draggable list component if re-ordering the list", async () => {
    renderWithRouterApollo(
      <AuthProvider>
        {withReactBeautifulDND(WorkTabsStructureFilesetList, {
          fileSets: mockFileSets,
          isReordering: true,
        })}
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock],
      }
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-draggable-list"));
    });
  });

  it("renders a non-draggable list if not-reordering", async () => {
    renderWithRouterApollo(
      <AuthProvider>
        {withReactBeautifulDND(WorkTabsStructureFilesetList, {
          fileSets: mockFileSets,
        })}
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock],
      }
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list"));
    });
  });

  it("renders the correct number of list elements", async () => {
    renderWithRouterApollo(
      <AuthProvider>
        {withReactBeautifulDND(WorkTabsStructureFilesetList, {
          fileSets: mockFileSets,
        })}
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock],
      }
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list").children).toHaveLength(3);
    });
  });
});
