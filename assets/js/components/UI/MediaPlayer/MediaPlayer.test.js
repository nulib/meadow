import React from "react";
import { render, screen } from "@testing-library/react";
import UIVideoPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import {
  mockVideoSources,
  mockVideoTracks,
} from "@js/components/UI/MediaPlayer/MediaPlayer";

describe("UIVideoPlayer component", () => {
  it("renders", () => {
    render(<UIVideoPlayer />);
    expect(screen.getByTestId("video-player"));
  });

  it("renders pass through props", () => {
    render(<UIVideoPlayer controls autoPlay={true} />);
    const videoEl = screen.getByTestId("video-player");

    expect(videoEl).toHaveAttribute("controls");
    expect(videoEl).toHaveAttribute("autoplay");
  });

  it("renders source elements", () => {
    render(<UIVideoPlayer sources={mockVideoSources} />);
    expect(screen.getAllByTestId("source-item")).toHaveLength(3);
  });

  it("renders VTT track elements", () => {
    render(<UIVideoPlayer tracks={mockVideoTracks} />);
    expect(screen.getAllByTestId("track")).toHaveLength(1);
  });
});
