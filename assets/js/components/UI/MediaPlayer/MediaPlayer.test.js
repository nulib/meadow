import React from "react";
import { render, screen } from "@testing-library/react";
import UIMediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";

jest.mock("@js/services/get-vtt-file");

export const mockVideoSources = [
  {
    id: "http://dlib.indiana.edu/iiif_av/volleyball/high/volleyball-for-boys.mp4",
    type: "Video",
    format: "video/mp4",
    height: 1080,
    width: 1920,
    duration: 662.037,
  },
  {
    id: "http://dlib.indiana.edu/iiif_av/volleyball/medium/volleyball-for-boys.mp4",
    type: "Video",
    format: "video/mp4",
    height: 1080,
    width: 1920,
    duration: 662.037,
  },
  {
    id: "http://dlib.indiana.edu/iiif_av/volleyball/low/volleyball-for-boys.mp4",
    type: "Video",
    format: "video/mp4",
    height: 1080,
    width: 1920,
    duration: 662.037,
  },
];

describe("UIMediaPlayer component", () => {
  it("renders", () => {
    render(<UIMediaPlayer />);
    expect(screen.getByTestId("video-player"));
  });

  it("renders pass through props", () => {
    render(<UIMediaPlayer controls autoPlay={true} />);
    const videoEl = screen.getByTestId("video-player");

    expect(videoEl).toHaveAttribute("controls");
    expect(videoEl).toHaveAttribute("autoplay");
  });

  it("renders source elements", () => {
    render(<UIMediaPlayer sources={mockVideoSources} />);
    expect(screen.getAllByTestId("source-item")).toHaveLength(3);
  });
});
