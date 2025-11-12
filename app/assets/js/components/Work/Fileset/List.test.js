import {
  renderWithRouterApollo,
  withReactBeautifulDND,
} from "@js/services/testing-helpers";
import { screen, waitFor } from "@testing-library/react";
import { CodeListProvider } from "@js/context/code-list-context";
import React from "react";
import WorkFilesetList from "@js/components/Work/Fileset/List";
import { WorkProvider } from "@js/context/work-context";
import { mockFileSets } from "@js/mock-data/filesets";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import {
  mockWork,
  mockWork2
} from "../work.gql.mock";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("WorkFilesetList component", () => {
  it("renders a draggable list component if re-ordering the list", async () => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: mockFileSets, auxiliary: [] },
            isReordering: true,
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-draggable-list"));
    });
  });

  it("renders a non-draggable list if not-reordering", async () => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: mockFileSets, auxiliary: [] },
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
    );
    await waitFor(() => {
      expect(screen.getByTestId("fileset-list"));
    });
  });

  it("renders the correct number of list elements", async () => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider>
          {withReactBeautifulDND(WorkFilesetList, {
            fileSets: { access: mockFileSets, auxiliary: [] },
          })}
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
    );
    await waitFor(() => {
      expect(screen.getAllByTestId("fileset-item")).toHaveLength(4);
    });
  });
});
