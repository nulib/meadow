import React from "react";
import { render, fireEvent } from "@testing-library/react";
//import ScreensIngestSheet from "./IngestSheet";
import { renderWithRouter } from "../../services/testing-helpers";

xtest("IngestSheet component loads", () => {
  const { container } = renderWithRouter(<ScreensIngestSheet />);
  expect(container).toBeTruthy();
});
