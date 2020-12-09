import React from "react";
import { render, screen } from "@testing-library/react";
import ScreensDashboardsBatchEditList from "./Details";
import { Route } from "react-router-dom";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

jest.mock("@js/services/elasticsearch");

describe("ScreensDashboardsBatchEditList component", () => {
  it("renders the component", () => {
    renderWithRouterApollo(
      <Route
        path="/dashboards/batch-edit/:id"
        component={ScreensDashboardsBatchEditList}
      />,
      {
        route: "/dashboards/batch-edit/ABCFOO123",
      }
    );
    expect(screen.getByTestId("dashboard-batch-edit-screen"));
    expect(screen.getByTestId("page-title"));
  });
});
