import React from "react";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import DashboardsProvenanceList from "./List";
import { GET_AI_ACTIVITIES } from "./provenance.gql";

const mocks = [
  {
    request: {
      query: GET_AI_ACTIVITIES,
      variables: { activityType: null, status: null, limit: 100 },
    },
    result: {
      data: {
        aiActivities: [
          {
            id: "activity-1",
            activityType: "metadata_plan",
            aiUseType: "metadata_generation",
            status: "completed",
            model: "claude-opus",
            modelProvider: "anthropic",
            workId: "work-1234abcd",
            costUsd: 0.0123,
            startedAt: "2026-01-01T00:00:00Z",
            completedAt: "2026-01-01T00:01:00Z",
            insertedAt: "2026-01-01T00:00:00Z",
          },
        ],
      },
    },
  },
];

describe("DashboardsProvenanceList", () => {
  it("renders activities returned by the query", async () => {
    const { getByText, getByTestId } = renderWithRouterApollo(
      <DashboardsProvenanceList />,
      { mocks },
    );
    expect(getByTestId("provenance-dashboard-list")).toBeInTheDocument();
    await waitFor(() => {
      expect(getByText("metadata_plan")).toBeInTheDocument();
    });
    expect(getByText("claude-opus")).toBeInTheDocument();
  });
});
