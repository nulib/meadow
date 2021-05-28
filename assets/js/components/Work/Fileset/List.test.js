import React from "react";
import WorkFilesetList from "@js/components/Work/Fileset/List";
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

describe("WorkFilesetList component", () => {
  it("renders a draggable list component if re-ordering the list", async () => {
    render(
      withReactBeautifulDND(WorkFilesetList, {
        fileSets: { access: mockFileSets, auxillary: [] },
        isReordering: true,
      })
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-draggable-list"));
    });
  });

  it("renders a non-draggable list if not-reordering", async () => {
    render(
      withReactBeautifulDND(WorkFilesetList, {
        fileSets: { access: mockFileSets, auxillary: [] },
      })
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list"));
    });
  });

  it("renders the correct number of list elements", async () => {
    render(
      withReactBeautifulDND(WorkFilesetList, {
        fileSets: { access: mockFileSets, auxillary: [] },
      })
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list").children).toHaveLength(3);
    });
  });
});
