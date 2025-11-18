// WorkTabsStructureTranscriptionPane.test.js
import React from "react";
import { render, screen } from "@testing-library/react";
import WorkTabsStructureTranscriptionPane from "./Pane";

describe("WorkTabsStructureTranscriptionPane", () => {
  it("renders a textarea with annotation content and calls callback", () => {
    const hasTranscriptionCallback = jest.fn();
    const annotation = {
      id: "ann-1",
      type: "transcription",
      content: "This is the transcription.",
    };

    render(
      <WorkTabsStructureTranscriptionPane
        annotation={annotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
        isGenerating={false}
      />,
    );

    const textarea = screen.getByRole("textbox");
    expect(textarea).toBeInTheDocument();
    expect(textarea).toHaveValue("This is the transcription.");
    expect(textarea).toHaveAttribute("data-annotation-id", "ann-1");
    expect(textarea).toHaveAttribute("data-annotation-type", "transcription");

    expect(hasTranscriptionCallback).toHaveBeenCalledTimes(1);
    expect(hasTranscriptionCallback).toHaveBeenCalledWith(true);
  });

  it("shows generating message when isGenerating and no annotation content", () => {
    const hasTranscriptionCallback = jest.fn();
    const annotation = {
      id: "ann-2",
      type: "transcription",
      content: null,
    };

    render(
      <WorkTabsStructureTranscriptionPane
        annotation={annotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
        isGenerating={true}
      />,
    );

    expect(
      screen.getByText("Generating transcription, please wait..."),
    ).toBeInTheDocument();

    // No textarea when generating with no content
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument();

    // Should not yet have called the callback
    expect(hasTranscriptionCallback).not.toHaveBeenCalled();
  });

  it("switches from generating state to showing textarea when content arrives", () => {
    const hasTranscriptionCallback = jest.fn();

    const initialAnnotation = {
      id: "ann-3",
      type: "transcription",
      content: null,
    };

    const { rerender } = render(
      <WorkTabsStructureTranscriptionPane
        annotation={initialAnnotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
        isGenerating={true}
      />,
    );

    // Initially: generating message
    expect(
      screen.getByText("Generating transcription, please wait..."),
    ).toBeInTheDocument();
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument();
    expect(hasTranscriptionCallback).not.toHaveBeenCalled();

    // Now simulate "transcription finished" – annotation gains content
    const updatedAnnotation = {
      ...initialAnnotation,
      content: "Final generated transcription",
    };

    rerender(
      <WorkTabsStructureTranscriptionPane
        annotation={updatedAnnotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
        isGenerating={false}
      />,
    );

    const textarea = screen.getByRole("textbox");
    expect(textarea).toBeInTheDocument();
    expect(textarea).toHaveValue("Final generated transcription");

    expect(hasTranscriptionCallback).toHaveBeenCalledTimes(1);
    expect(hasTranscriptionCallback).toHaveBeenCalledWith(true);
  });
});
