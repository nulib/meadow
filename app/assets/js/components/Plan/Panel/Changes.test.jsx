import React from "react";
import { fireEvent, render, screen } from "@testing-library/react";

jest.mock("@apollo/client/react", () => ({
  useMutation: () => [jest.fn()],
}));

jest.mock("@js/components/Plan/Panel/Diff", () => ({
  __esModule: true,
  default: ({ currentWork }) => (
    <div
      data-testid="diff"
      data-has-current-work={currentWork !== undefined ? "true" : "false"}
    />
  ),
}));

jest.mock("@js/components/UI/Loader", () => ({
  __esModule: true,
  default: () => <div data-testid="loader" />,
}));

jest.mock("@js/components/UI/Skeleton", () => ({
  __esModule: true,
  default: ({ rows = 3 }) => <div data-testid="skeleton" data-rows={rows} />,
}));

jest.mock("@js/components/Icon", () => ({
  IconAlert: () => <span data-testid="icon-alert" />,
  IconMagic: () => <span data-testid="icon-magic" />,
}));

const { default: PlanPanelChanges } = await import("./Changes");

const baseProps = {
  changes: { planChange: {} },
  id: "plan-1",
  plan: { status: "APPROVED" },
  loadingMessage: "Loading",
  logs: [],
  summary: "Changes summary",
  originalPrompt: "Describe the desired edits",
  target: {
    title: "Work title",
    thumbnails: <div data-testid="thumb" />,
  },
  onCompleted: jest.fn(),
};

describe("PlanPanelChanges", () => {
  test("forwards currentWork prop to the Diff component", async () => {
    const currentWork = { descriptiveMetadata: { title: "A Work" } };
    render(<PlanPanelChanges {...baseProps} currentWork={currentWork} />);

    const diff = await screen.findByTestId("diff");
    expect(diff).toHaveAttribute("data-has-current-work", "true");
  });

  test("renders without error when currentWork is not provided", async () => {
    render(<PlanPanelChanges {...baseProps} />);

    const diff = await screen.findByTestId("diff");
    expect(diff).toHaveAttribute("data-has-current-work", "false");
  });

  test("renders the user prompt above the summary", async () => {
    render(<PlanPanelChanges {...baseProps} />);

    expect(
      await screen.findByRole("heading", { name: /prompt/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(baseProps.originalPrompt)).toBeInTheDocument();
    expect(
      screen.getByRole("heading", { name: /summary/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(baseProps.summary)).toBeInTheDocument();
  });

  test("shows a skeleton placeholder when the prompt is missing", async () => {
    render(
      <PlanPanelChanges {...baseProps} originalPrompt={null} summary={null} />,
    );

    expect(
      await screen.findByRole("heading", { name: /prompt/i }),
    ).toBeInTheDocument();
    expect(screen.getAllByTestId("skeleton").length).toBeGreaterThan(0);
  });

  test("shows the apply-reminder callout when status is APPROVED", async () => {
    // baseProps already sets plan.status = "APPROVED"
    render(<PlanPanelChanges {...baseProps} />);

    expect(
      await screen.findByText(/your changes are not saved yet/i),
    ).toBeInTheDocument();
    expect(screen.getByTestId("icon-alert")).toBeInTheDocument();
  });

  test("does not show the apply-reminder callout when status is PROPOSED", async () => {
    render(
      <PlanPanelChanges
        {...baseProps}
        plan={{ status: "PROPOSED" }}
        changes={{ planChange: { status: "PROPOSED" } }}
      />,
    );

    // The PROPOSED branch shows a loading spinner; wait for the diff to settle
    // without the callout being present
    expect(
      screen.queryByText(/your changes are not saved yet/i),
    ).not.toBeInTheDocument();
  });

  test("toggles the log panel", async () => {
    render(<PlanPanelChanges {...baseProps} logs={["[info] first log"]} />);

    const showLogsButton = await screen.findByRole("button", {
      name: /show logs/i,
    });
    expect(screen.queryByRole("log")).not.toBeInTheDocument();

    fireEvent.click(showLogsButton);
    expect(screen.getByRole("log")).toBeInTheDocument();
    expect(screen.getByText("[info] first log")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /hide logs/i }));
    expect(screen.queryByRole("log")).not.toBeInTheDocument();
  });
});
