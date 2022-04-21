import React from "react";
import DashboardsCsvTitleBar from "./TitleBar";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { mockUser } from "@js/components/Auth/auth.gql.mock";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("DashboardsCsvTitleBar component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsCsvTitleBar />);
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-job-title-bar"));
    expect(screen.getByTestId("csv-dashboard-title"));
  });

  it("renders import modal component", () => {
    expect(screen.getByTestId("csv-job-import-wrapper"));
  });
});
