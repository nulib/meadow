import React from "react";
import { render, cleanup } from "@testing-library/react";
import IngestSheetList from "./List";
import "@testing-library/jest-dom/extend-expect";
import { renderWithRouter } from "../../services/testing-helpers";

const projectId = "abcdefg123";

afterEach(cleanup);

xtest("IngestSheetList component renders", () => {
  const { container } = renderWithRouter(
    <IngestSheetList projectId={projectId} />
  );
  expect(container).toBeTruthy();
});

xtest("Displays a message that no sheets exist", () => {
  const { queryByTestId } = render(<IngestSheetList projectId={projectId} />);
  expect(queryByTestId("no-ingest-sheets-notification")).toBeVisible();
});

xtest("Displays a list of ingest sheets", () => {
  const { queryByTestId } = render(<IngestSheetList projectId={projectId} />);
  expect(queryByTestId("ingest-sheet-list")).toBeVisible();
});
