import { screen, within } from "@testing-library/react";
import React from "react";
import WorkTabsPreservation from "./Preservation";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import {
  mockWork,
  verifyFileSetsMock,
  workArchiverEndpointMock,
} from "@js/components/Work/work.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("WorkTabsPreservation component", () => {
  beforeEach(() => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkTabsPreservation work={mockWork} />
      </CodeListProvider>,
      {
        mocks: [
          verifyFileSetsMock,
          workArchiverEndpointMock,
          ...allCodeListMocks,
        ],
      }
    );
  });

  it("renders the component and tab title", async () => {
    expect(await screen.findByTestId("preservation-tab"));
    expect(screen.getByText("Preservation and Access"));
  });

  it("renders preservation column headers", async () => {
    const cols = ["Role", "Filename", "Created", "Verified"];
    const th = await screen.findByText("Filename");
    const row = th.closest("tr");
    const utils = within(row);
    for (let col of cols) {
      expect(await utils.findByText(col));
    }
  });

  it("renders the correct number of preservation record rows", async () => {
    const rows = await screen.findAllByTestId("preservation-row");
    expect(rows).toHaveLength(4);
  });

  it("renders correct batch job row details", async () => {
    const td = await screen.findByText(mockWork.fileSets[0].id);
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText("A"));
    expect(utils.getByText(/coffee.jpg/i));
    expect(utils.getByText("Sep 12, 2020 10:01 AM"));
  });

  it("renders a verified status in the fileset row", async () => {
    const td = await screen.findByText(mockWork.fileSets[0].id);
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("verified")).toHaveTextContent(/verified/i);

    const td2 = await screen.findByText(mockWork.fileSets[1].id);
    const row2 = td2.closest("tr");
    const utils2 = within(row2);
    expect(utils2.getByTestId("verified")).not.toHaveTextContent(/verified/i);
  });

  it("renders the correct menu options in the action dropdown", async () => {
    const td = await screen.findByText(mockWork.fileSets[0].id);
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("button-copy-id"));
    expect(utils.getByTestId("button-fileset-delete"));
    expect(utils.getByTestId("button-copy-preservation-location"));
    expect(utils.getByTestId("button-copy-checksum"));
  });

  it("renders a copy fileset id button in the row", async () => {
    const td = await screen.findByText(mockWork.fileSets[0].id);
    const row = td.closest("tr");
    const utils = within(row);
  });

  it("renders a delete Work button", async () => {
    expect(await screen.findByTestId("button-work-delete"));
  });
});
