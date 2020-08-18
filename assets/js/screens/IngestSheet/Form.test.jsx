import React from "react";
import { render, fireEvent, cleanup } from "@testing-library/react";
import ScreensIngestSheetForm from "./Form";
import "@testing-library/jest-dom/extend-expect";
import { renderWithRouter } from "../../services/testing-helpers";

jest.mock("../../services/elasticsearch");

afterEach(cleanup);

xtest("ScreensIngestSheet upload form component renders", () => {
  const { container } = renderWithRouter(<ScreensIngestSheetForm />, {
    route: "/project/01DESDW646M02M8S8R9B4Y98W9/ingest-sheet/upload",
  });

  expect(container).toBeTruthy();
});
