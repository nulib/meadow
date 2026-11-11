import React from "react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, mock } from "bun:test";
import RunBar from "./RunBar";
import { runSize } from "./limits";

describe("transcription bench RunBar", () => {
  it("starts a run within the cap, with its name", async () => {
    const onRun = mock(() => Promise.resolve());
    render(<RunBar size={runSize(2, 2, 2)} onRun={onRun} />);

    expect(
      screen.getByText(/2 images × 2 models × 2 variants = 8 transcriptions/),
    ).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText("Run name"), "  Newspaper ");
    await userEvent.click(
      screen.getByRole("button", { name: "Run 8 transcriptions" }),
    );
    expect(onRun).toHaveBeenCalledWith("Newspaper");
  });

  it("refuses a run over the cap and says why", () => {
    const onRun = mock(() => Promise.resolve());
    render(<RunBar size={runSize(2, 3, 2)} onRun={onRun} />);

    expect(
      screen.getByRole("button", { name: "Run 12 transcriptions" }),
    ).toBeDisabled();
    expect(screen.getByRole("alert")).toHaveTextContent(
      "2 images × 3 models × 2 variants = 12 transcriptions. A run is capped at 10",
    );
  });

  it("asks for a pick of each kind and shows what the server refused", async () => {
    const { rerender } = render(
      <RunBar size={runSize(0, 1, 1)} onRun={() => Promise.resolve()} />,
    );
    expect(
      screen.getByRole("button", {
        name: "Pick an image, a model and a variant",
      }),
    ).toBeDisabled();

    rerender(
      <RunBar
        size={runSize(1, 1, 1)}
        onRun={() => Promise.reject(new Error("A run is limited to 10"))}
      />,
    );
    await userEvent.click(
      screen.getByRole("button", { name: "Run 1 transcription" }),
    );
    expect(
      await screen.findByText("A run is limited to 10"),
    ).toBeInTheDocument();
  });
});
