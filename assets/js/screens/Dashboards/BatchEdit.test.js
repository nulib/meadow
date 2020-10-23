import React from "react";
import { render, screen } from "@testing-library/react";
import { renderWithRouter } from "@js/services/testing-helpers";
import ScreensDashboardsBatchEdit from "./BatchEdit";

jest.mock("../../services/elasticsearch");

describe("ScreensDashboardsBatchEdit component", () => {
  beforeEach(() => {
    renderWithRouter(<ScreensDashboardsBatchEdit />);
  });
  it("renders the component and screen title", () => {
    expect(screen.getByTestId("dashboard-batch-edit-screen"));
    expect(screen.getByTestId("batch-edit-dashboard-title"));
  });
});
