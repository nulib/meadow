import React from "react";
import { render, screen } from "@testing-library/react";
import PlanPanelChanges from "./Changes";

jest.mock("@apollo/client", () => ({
  useMutation: () => [jest.fn()],
}));

jest.mock("@js/components/Plan/Panel/Diff", () => () => (
  <div data-testid="diff" />
));

jest.mock("@js/components/UI/Loader", () => () => (
  <div data-testid="loader" />
));

jest.mock("@js/components/UI/Skeleton", () => ({ rows = 3 }) => (
  <div data-testid="skeleton" data-rows={rows} />
));

jest.mock("@js/components/Icon", () => ({
  IconMagic: () => <span data-testid="icon-magic" />,
}));

const baseProps = {
  changes: { planChange: {} },
  id: "plan-1",
  plan: { status: "APPROVED" },
  loadingMessage: "Loading",
  summary: "Changes summary",
  originalPrompt: "Describe the desired edits",
  target: {
    title: "Work title",
    thumbnails: <div data-testid="thumb" />,
  },
  onCompleted: jest.fn(),
};

describe("PlanPanelChanges", () => {
  test("renders the user prompt above the summary", async () => {
    render(<PlanPanelChanges {...baseProps} />);

    expect(
      await screen.findByRole("heading", { name: /prompt/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(baseProps.originalPrompt)).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /summary/i })).toBeInTheDocument();
    expect(screen.getByText(baseProps.summary)).toBeInTheDocument();
  });

  test("shows a skeleton placeholder when the prompt is missing", async () => {
    render(
      <PlanPanelChanges
        {...baseProps}
        originalPrompt={null}
        summary={null}
      />,
    );

    expect(
      await screen.findByRole("heading", { name: /prompt/i }),
    ).toBeInTheDocument();
    expect(screen.getAllByTestId("skeleton").length).toBeGreaterThan(0);
  });
});

