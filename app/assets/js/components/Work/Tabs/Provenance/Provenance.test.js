import React from "react";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import WorkTabsProvenance from "./Provenance";

const workWithProvenance = {
  id: "work-1",
  aiProvenanceSummary: [
    {
      fieldPath: "descriptive_metadata.description",
      targetType: "Work",
      targetId: "work-1",
      origin: "ai_generated",
      status: "applied",
      activityId: "activity-1",
      activityType: "metadata_direct_apply",
      aiUseType: "metadata_generation",
      model: "claude-opus",
      modelProvider: "anthropic",
      generatedAt: "2026-01-01T00:00:00Z",
      reviewer: "jane",
      reviewedAt: "2026-01-02T00:00:00Z",
      appliedAt: "2026-01-03T00:00:00Z",
      latestEventType: "applied",
      sourceCount: 1,
      citationCompleteness: "complete",
    },
  ],
};

describe("WorkTabsProvenance", () => {
  it("renders an empty state when there is no provenance", () => {
    const { getByTestId } = renderWithRouterApollo(
      <WorkTabsProvenance work={{ id: "work-1", aiProvenanceSummary: [] }} />,
      { mocks: [] },
    );
    expect(getByTestId("provenance-empty")).toBeInTheDocument();
  });

  it("renders the summary table with field-level provenance", async () => {
    const { getByTestId, getByText } = renderWithRouterApollo(
      <WorkTabsProvenance work={workWithProvenance} />,
      { mocks: [] },
    );
    await waitFor(() => {
      expect(getByTestId("provenance-summary-table")).toBeInTheDocument();
    });
    expect(getByText("descriptive_metadata.description")).toBeInTheDocument();
    expect(getByTestId("provenance-origin-badge")).toHaveTextContent(
      "AI generated",
    );
  });

  it("shows the live current value, not the stale AI proposal", async () => {
    const work = {
      id: "work-1",
      aiProvenanceSummary: [
        {
          ...workWithProvenance.aiProvenanceSummary[0],
          fieldPath: "descriptive_metadata.title",
          origin: "human_attested_after_ai",
          proposedValue: { value: "AI title" },
          currentValue: { value: "Cataloger title" },
        },
      ],
    };
    const { getByText, queryByText } = renderWithRouterApollo(
      <WorkTabsProvenance work={work} />,
      { mocks: [] },
    );
    await waitFor(() => {
      expect(getByText("Cataloger title")).toBeInTheDocument();
    });
    expect(queryByText("AI title")).not.toBeInTheDocument();
  });
});
