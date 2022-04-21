import React from "react";
import DashboardsCsvDetails from "./Details";
import { render, screen, within } from "@testing-library/react";
import { errors } from "@js/components/Dashboards/Csv/Errors.test";

const csvMetadataUpdateJob = {
  __typename: "CsvMetadataUpdateJob",
  id: "86fc5bed-1809-482b-b81c-255a0962cfcc",
  errors: [],
  filename: "will-fail-header-validation.csv",
  insertedAt: "2021-01-25T18:56:28.858293Z",
  rows: null,
  startedAt: null,
  status: "invalid",
  updatedAt: "2021-01-25T18:56:33.542422Z",
  user: "aja0137",
};

describe("DashboardCsvDetails component", () => {
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

  it("renders csv job fields", () => {
    expect(screen.getByText("will-fail-header-validation.csv"));
    expect(screen.getByText("invalid"));
    expect(screen.getByText("aja0137"));
  });

  describe("displaying errors", () => {
    it("displays errors only if they exist in the job", () => {
      render(
        <DashboardsCsvDetails csvMetadataUpdateJob={csvMetadataUpdateJob} />
      );
      expect(screen.queryByTestId("csv-job-errors")).toBeNull();

      render(
        <DashboardsCsvDetails
          csvMetadataUpdateJob={{ ...csvMetadataUpdateJob, errors: errors }}
        />
      );
      expect(screen.queryByTestId("csv-job-errors"));
    });
  });
});
