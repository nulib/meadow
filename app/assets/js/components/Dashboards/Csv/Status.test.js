import React from "react";
import DashboardsCsvStatus from "./Status";
import { render, screen } from "@testing-library/react";

describe("DashboardCsvStatus component", () => {
  it("renders a success status", () => {
    render(<DashboardsCsvStatus status="completed" />);
    const statusEl = screen.getByTestId("csv-job-status");
    expect(statusEl).toHaveTextContent(/completed/i);
    expect(statusEl.className.includes("-isSuccess-true")).toBeTruthy();
  });

  it("renders invalid status", () => {
    render(<DashboardsCsvStatus status="invalid" />);
    const statusEl = screen.getByTestId("csv-job-status");
    expect(statusEl).toHaveTextContent(/invalid/i);
    expect(statusEl.className.includes("-isDanger-true")).toBeTruthy();
  });
});
