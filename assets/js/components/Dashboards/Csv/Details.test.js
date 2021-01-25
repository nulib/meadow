import React from "react";
import DashboardsCsvDetails from "./Details";
import { render, screen, within } from "@testing-library/react";

const csvMetadataUpdateJob = {
  __typename: "CsvMetadataUpdateJob",
  id: "86fc5bed-1809-482b-b81c-255a0962cfcc",
  errors: [],
  filename: "will-fail-header-validation.csv",
  insertedAt: "2021-01-25T18:56:28.858293Z",
  rows: null,
  source:
    "s3://dev-uploads/csv_metadata/3c6f039c-8afd-42d8-b4b2-4fd135558dc3.csv",
  startedAt: null,
  status: "invalid",
  updatedAt: "2021-01-25T18:56:33.542422Z",
  user: "aja0137",
};

describe("DdashboardCsvDetails component", () => {
  beforeEach(() => {
    render(
      <DashboardsCsvDetails csvMetadataUpdateJob={csvMetadataUpdateJob} />
    );
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-job-details"));
  });

  it("renders the status", () => {
    expect(screen.getByTestId("csv-job-status-wrapper"));
  });
});
