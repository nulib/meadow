import React from "react";
import { render, fireEvent, cleanup } from "@testing-library/react";
import ScreensIngestSheet from "./IngestSheet";
import "@testing-library/jest-dom/extend-expect";
import { renderWithRouter } from "../../testing-helpers";

afterEach(cleanup);

xtest("IngestSheet component loads", () => {
  const { container } = renderWithRouter(<ScreensIngestSheet />);
  expect(container).toBeTruthy();
});
