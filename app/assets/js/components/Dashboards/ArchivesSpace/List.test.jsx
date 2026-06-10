import React from "react";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import DashboardsArchivesSpaceList from "./List";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import {
  listArchivesSpaceImportsMock,
  listArchivesSpaceImportsEmptyMock,
  MOCK_RESOURCE_TITLE,
} from "@js/components/Project/archivesSpace.gql.mock";

function renderList(dataMock, userMock = getCurrentUserMock) {
  return renderWithRouterApollo(<DashboardsArchivesSpaceList />, {
    mocks: [dataMock, userMock],
  });
}

describe("DashboardsArchivesSpaceList", () => {
  it("lists imported ArchivesSpace resources", async () => {
    renderList(listArchivesSpaceImportsMock);

    expect(await screen.findByText(MOCK_RESOURCE_TITLE)).toBeInTheDocument();
    expect(
      screen.getByTestId("archivesspace-imports-table"),
    ).toBeInTheDocument();
    expect(screen.getAllByTestId("archivesspace-import-row")).toHaveLength(1);
    expect(screen.getByText("5")).toBeInTheDocument();
    expect(screen.getByTestId("link-finding-aid")).toHaveAttribute(
      "href",
      "https://findingaids.example.edu/63",
    );
  });

  it("shows an empty state when there are no imports", async () => {
    renderList(listArchivesSpaceImportsEmptyMock);

    expect(
      await screen.findByTestId("archivesspace-imports-empty"),
    ).toBeInTheDocument();
  });

  it("shows the ingest button for authorized managers", async () => {
    renderList(listArchivesSpaceImportsEmptyMock, getCurrentUserMock);

    expect(
      await screen.findByTestId("button-archivesspace-ingest"),
    ).toBeInTheDocument();
  });
});
