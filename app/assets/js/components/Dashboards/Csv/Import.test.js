import React from "react";
import DashboardsCsvImport from "./Import";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql";

describe("DashboardsCsvImport component", () => {
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
    renderWithRouterApollo(<DashboardsCsvImport />, {
      mocks: [presignedUrlMock],
    });
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-job-import-wrapper"));
  });

  it("renders the import button", () => {
    expect(screen.getByTestId("import-csv-button"));
  });

  it("renders the import modal component", () => {
    expect(screen.getByTestId("import-csv-modal"));
  });
});
