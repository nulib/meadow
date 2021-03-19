import { screen, within } from "@testing-library/react";
import React from "react";
import WorkTabsPreservation from "./Preservation";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import {
  mockWork,
  verifyFileSetsMock,
} from "@js/components/Work/work.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("WorkTabsPreservation component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<WorkTabsPreservation work={mockWork} />, {
      mocks: [verifyFileSetsMock],
    });
  });

  it("renders the component and tab title", async () => {
    expect(await screen.findByTestId("preservation-tab"));
    expect(screen.getByText("Preservation and Access"));
  });

  it("renders preservation column headers", async () => {
    const cols = [
      "Role",
      "Filename",
      "Checksum",
      "s3 Key",
      "Verified",
      "Actions",
    ];
    const th = await screen.findByText("Checksum");
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
    expect(utils.getByText("Access"));
    expect(utils.getByText(/coffee.jpg/i));
    expect(utils.getByText("s3://bucket/foo/bar"));
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

  it("renders a delete Fileset button in the row", async () => {
    const td = await screen.findByText(mockWork.fileSets[0].id);
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("button-fileset-delete"));
  });

  it("renders a delete Work button", async () => {
    expect(await screen.findByTestId("button-work-delete"));
  });
});
