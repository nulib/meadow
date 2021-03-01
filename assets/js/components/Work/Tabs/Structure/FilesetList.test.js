import React from "react";
import WorkTabsStructureFilesetList from "./FilesetList";
import { render, screen, waitFor } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import { withReactBeautifulDND } from "@js/services/testing-helpers";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("WorkTabsStructureFilesets components", () => {
  it("renders a draggable list component if re-ordering the list", async () => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        fileSets: mockFileSets,
        isReordering: true,
      })
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-draggable-list"));
    });
  });

  it("renders a non-draggable list if not-reordering", async () => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        fileSets: mockFileSets,
      })
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list"));
    });
  });

  it("renders the correct number of list elements", async () => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        fileSets: mockFileSets,
      })
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list").children).toHaveLength(3);
    });
  });
});
