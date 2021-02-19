import React from "react";
import DashboardsCsvErrors from "./Errors";
import { render, screen, within } from "@testing-library/react";

export const errors = [
  {
    __typename: "RowErrors",
    errors: [
      { __typename: "Errors", field: "location", messages: ["is missing"] },
      { __typename: "Errors", field: "status", messages: ["is missing"] },
      {
        __typename: "Errors",
        field: "project_cycle",
        messages: ["is missing"],
      },
      { __typename: "Errors", field: "visibility", messages: ["is missing"] },
      {
        __typename: "Errors",
        field: "project_proposer",
        messages: ["is missing"],
      },
      { __typename: "Errors", field: "notes", messages: ["is missing"] },
      { __typename: "Errors", field: "box_number", messages: ["is missing"] },
      { __typename: "Errors", field: "title", messages: ["is missing"] },
      { __typename: "Errors", field: "Donohue_001", messages: ["is unknown"] },
      { __typename: "Errors", field: "project_desc", messages: ["is missing"] },
      {
        __typename: "Errors",
        field: "accession_number",
        messages: ["is missing"],
      },
      {
        __typename: "Errors",
        field: "table_of_contents",
        messages: ["is missing"],
      },
      { __typename: "Errors", field: "source", messages: ["is missing"] },
      { __typename: "Errors", field: "catalog_key", messages: ["is missing"] },
    ],
    row: 1,
  },
  {
    __typename: "RowErrors",
    errors: [
      { __typename: "Errors", field: "location", messages: ["is missing"] },
      { __typename: "Errors", field: "status", messages: ["is missing"] },
      {
        __typename: "Errors",
        field: "project_cycle",
        messages: ["is missing"],
      },
      { __typename: "Errors", field: "visibility", messages: ["is missing"] },
      {
        __typename: "Errors",
        field: "project_proposer",
        messages: ["is missing"],
      },
      { __typename: "Errors", field: "notes", messages: ["is missing"] },
      { __typename: "Errors", field: "box_number", messages: ["is missing"] },
      { __typename: "Errors", field: "title", messages: ["is missing"] },
      { __typename: "Errors", field: "Donohue_001", messages: ["is unknown"] },
      { __typename: "Errors", field: "project_desc", messages: ["is missing"] },
      {
        __typename: "Errors",
        field: "accession_number",
        messages: ["is missing"],
      },
      {
        __typename: "Errors",
        field: "table_of_contents",
        messages: ["is missing"],
      },
      { __typename: "Errors", field: "source", messages: ["is missing"] },
      { __typename: "Errors", field: "catalog_key", messages: ["is missing"] },
    ],
    row: 2,
  },
];

describe("DashboardsCsvErrors component", () => {
  beforeEach(() => {
    render(<DashboardsCsvErrors errors={errors} />);
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-job-errors"));
  });

  it("renders the Errors table with correct number of rows", () => {
    expect(screen.getByTestId("csv-job-errors-table"));
    expect(screen.getAllByTestId("csv-job-errors-row")).toHaveLength(2);
  });

  it("renders the right number of error messages in a row", () => {
    const rows = screen.getAllByTestId("csv-job-errors-row");
    const utils = within(rows[0]);
    const errorMessages = utils.getAllByTestId("csv-job-error-message");
    expect(errorMessages).toHaveLength(14);

    expect(errorMessages[0]).toHaveTextContent("location");
    expect(errorMessages[0]).toHaveTextContent("is missing");

    expect(errorMessages[3]).toHaveTextContent("visibility");
    expect(errorMessages[3]).toHaveTextContent("is missing");
  });
});
