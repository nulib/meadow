import React from "react";
import { screen, waitFor } from "@testing-library/react";

import IngestSheetCompleted from "./Completed";
import {
  INGEST_SHEET_COMPLETED_ERRORS,
  INGEST_SHEET_WORKS,
  INGEST_SHEET_WORK_COUNT,
} from "./ingestSheet.gql";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

jest.mock("@nulib/design-system", () => {
  const React = require("react");
  return {
    Button: ({ children, isPrimary, ...props }) => (
      <button {...props}>{children}</button>
    ),
  };
});

jest.mock("./Completed/Errors", () => {
  const React = require("react");
  return {
    __esModule: true,
    default: ({ errors }) => (
      <div data-testid="completed-errors">{errors.length} errors</div>
    ),
  };
});

const sheetId = "sheet-1";

const worksMock = () => ({
  request: {
    query: INGEST_SHEET_WORKS,
    variables: { id: sheetId, limit: 10 },
  },
  result: { data: { ingestSheetWorks: [] } },
});

const errorsMock = (errors) => ({
  request: {
    query: INGEST_SHEET_COMPLETED_ERRORS,
    variables: { id: sheetId },
  },
  result: { data: { ingestSheetErrors: errors } },
});

const workCountMock = (fail) => ({
  request: { query: INGEST_SHEET_WORK_COUNT, variables: { id: sheetId } },
  result: {
    data: {
      ingestSheetWorkCount: {
        totalWorks: 1,
        totalFileSets: 2,
        appendedFileSets: 0,
        pass: 2 - fail,
        fail,
      },
    },
  },
});

const anError = {
  accessionNumber: "Donohue_001_01",
  action: "CopyFileToPreservation",
  description: "a page",
  errors: "it broke",
  filename: "coffee.tif",
  outcome: "error",
  rowNumber: 1,
  workAccessionNumber: "Donohue_001",
  role: "A",
};

// The sheet finished with errors, the failed file sets were retried, and it
// finished clean the second time. The second round of query results is what
// should be on screen once the status prop moves.
const mocks = [
  worksMock(),
  errorsMock([anError]),
  workCountMock(1),
  worksMock(),
  errorsMock([]),
  workCountMock(0),
];

const renderCompleted = (status) =>
  renderWithRouterApollo(
    <IngestSheetCompleted sheetId={sheetId} status={status} title="A Sheet" />,
    { mocks },
  );

describe("IngestSheetCompleted", () => {
  it("re-reads the sheet's errors and counts when the status changes", async () => {
    const { rerender } = renderCompleted("COMPLETED_ERROR");

    expect(await screen.findByTestId("completed-errors")).toHaveTextContent(
      "1 errors",
    );

    rerender(
      <IngestSheetCompleted
        sheetId={sheetId}
        status="COMPLETED"
        title="A Sheet"
      />,
    );

    await waitFor(() =>
      expect(screen.queryByTestId("completed-errors")).toBeNull(),
    );
  });

  it("leaves the queries alone while the status holds steady", async () => {
    const { rerender } = renderCompleted("COMPLETED_ERROR");

    expect(await screen.findByTestId("completed-errors")).toHaveTextContent(
      "1 errors",
    );

    rerender(
      <IngestSheetCompleted
        sheetId={sheetId}
        status="COMPLETED_ERROR"
        title="Renamed Sheet"
      />,
    );

    // Still the first round of results: no refetch, so the stale-looking view
    // here is the correct one.
    expect(screen.getByTestId("completed-errors")).toHaveTextContent(
      "1 errors",
    );
  });
});
