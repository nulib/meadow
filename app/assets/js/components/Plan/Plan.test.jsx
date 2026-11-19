import React from "react";
import { render, screen } from "@testing-library/react";

jest.mock("@js/hooks/usePlanChanges", () => ({
  usePlanChanges: () => ({ data: null, error: null }),
}));

jest.mock("@js/hooks/usePlan", () => ({
  usePlan: () => ({ data: null, error: null }),
}));

jest.mock("@js/hooks/useChatResponse", () => ({
  useChatResponse: () => ({ data: null, error: null }),
}));

jest.mock("@js/hooks/useSendChatMessage", () => ({
  useSendChatMessage: () => ({ sendChatMessage: jest.fn(), error: null }),
}));

jest.mock("@js/components/Plan/Chat/Form", () => ({
  __esModule: true,
  default: () => <div data-testid="plan-chat-form" />,
}));

jest.mock("@js/components/Plan/Panel/Changes", () => ({
  __esModule: true,
  default: () => <div data-testid="plan-panel-changes" />,
}));

jest.mock("@js/services/helpers", () => ({
  toastWrapper: jest.fn(),
}));

const { default: Plan } = await import("./Plan");

const buildWork = (overrides = {}) => ({
  id: "472e549f-beeb-444c-a1c8-660a8c85caf9",
  descriptiveMetadata: { title: "Crate & Barrel Poster" },
  representativeImage:
    "https://iiif.example.edu/iiif/3/1f115092-b94e-4091-ac45-b82c69ceaa90",
  ...overrides,
});

describe("Plan", () => {
  test("renders a square thumbnail from the work's representative image", () => {
    render(<Plan works={[buildWork()]} />);

    const thumbnail = screen.getByRole("img", {
      name: "Crate & Barrel Poster",
    });
    expect(thumbnail.querySelector("image")).toHaveAttribute(
      "href",
      "https://iiif.example.edu/iiif/3/1f115092-b94e-4091-ac45-b82c69ceaa90/square/%5E100,/0/default.jpg",
    );
  });

  test("renders without a thumbnail when the representative image is null", () => {
    render(<Plan works={[buildWork({ representativeImage: null })]} />);

    expect(screen.queryByRole("img")).not.toBeInTheDocument();
    expect(screen.getByText("Crate & Barrel Poster")).toBeInTheDocument();
    expect(screen.getByTestId("plan-chat-form")).toBeInTheDocument();
  });

  test("renders thumbnails only for works that have a representative image", () => {
    render(
      <Plan
        works={[
          buildWork({ id: "with-image", descriptiveMetadata: { title: "A" } }),
          buildWork({
            id: "without-image",
            descriptiveMetadata: { title: "B" },
            representativeImage: null,
          }),
        ]}
      />,
    );

    expect(screen.getAllByRole("img")).toHaveLength(1);
    expect(screen.getByRole("img", { name: "A" })).toBeInTheDocument();
    expect(screen.getByText("2 works")).toBeInTheDocument();
  });
});
