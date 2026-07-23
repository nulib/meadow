import {
  renderWithRouterApollo,
  withReactBeautifulDND,
} from "@js/services/testing-helpers";
import { screen, waitFor, within } from "@testing-library/react";
import { CodeListProvider } from "@js/context/code-list-context";
import React from "react";
import WorkFilesetList from "@js/components/Work/Fileset/List";
import { WorkProvider, defaultState } from "@js/context/work-context";
import { mockFileSets } from "@js/mock-data/filesets";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { mockWork, mockWork2 } from "../work.gql.mock";
import userEvent from "@testing-library/user-event";

useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("WorkFilesetList component", () => {
  it("renders a draggable list component if re-ordering the list", async () => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider initialState={{ ...defaultState, work: mockWork }}>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: mockFileSets, auxiliary: [] },
            isReordering: true,
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      },
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-draggable-list"));
    });
  });

  it("renders a non-draggable list if not-reordering", async () => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider initialState={{ ...defaultState, work: mockWork }}>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: mockFileSets, auxiliary: [] },
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      },
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list"));
    });
  });

  it("renders the correct number of list elements", async () => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider initialState={{ ...defaultState, work: mockWork }}>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: mockFileSets, auxiliary: [] },
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      },
    );
    await waitFor(() => {
      expect(screen.getAllByTestId("fileset-item")).toHaveLength(4);
    });
  });

  it("shows applicable candidates in the Attach filesets dropdown when reordering", async () => {
    const reorderableFileSets = [
      {
        id: "fileset-a",
        accessionNumber: "Acc_A",
        role: { id: "A", label: "Access" },
        groupWith: null,
        coreMetadata: { label: "Fileset A" },
      },
      {
        id: "fileset-b",
        accessionNumber: "Acc_B",
        role: { id: "A", label: "Access" },
        groupWith: null,
        coreMetadata: { label: "Fileset B" },
      },
    ];

    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider initialState={{ ...defaultState, work: mockWork }}>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: reorderableFileSets, auxiliary: [] },
            isReordering: true,
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      },
    );

    const user = userEvent.setup();
    const [groupAdd] = await screen.findAllByTestId("fileset-group-add");
    const input = within(groupAdd).getByPlaceholderText("Attach filesets...");
    await user.click(input);

    expect(
      within(groupAdd).queryByText("Applicable fileset(s) not found."),
    ).not.toBeInTheDocument();

    const candidates = within(groupAdd).getAllByTestId(
      "fileset-group-add-candidate",
    );
    expect(candidates).toHaveLength(1);
    expect(candidates[0]).toHaveTextContent("Fileset B");
  });
});
