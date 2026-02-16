import React from "react";
import DashboardsCsvTitleBar from "./TitleBar";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("DashboardsCsvTitleBar component", () => {
  const presignedUrlMock = {
    request: {
      query: GET_PRESIGNED_URL,
      variables: { uploadType: "CSV_METADATA" },
    },
    result: {
      data: {
        presignedUrl: { url: "https://example.test/presigned.csv" },
      },
    },
  };

  beforeEach(() => {
    renderWithRouterApollo(<DashboardsCsvTitleBar />, {
      mocks: [presignedUrlMock],
    });
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-job-title-bar"));
    expect(screen.getByTestId("csv-dashboard-title"));
  });

  it("renders import modal component", () => {
    expect(screen.getByTestId("csv-job-import-wrapper"));
  });
});
