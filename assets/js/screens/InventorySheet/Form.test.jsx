import React from "react";
import { render, fireEvent, cleanup } from "@testing-library/react";
import ScreensInventorySheetForm from "./Form";
import "@testing-library/jest-dom/extend-expect";
import { renderWithRouter } from "../../testing-helpers";

afterEach(cleanup);

xtest("ScreensInventorySheet upload form component renders", () => {
  const { container } = renderWithRouter(<ScreensInventorySheetForm />, {
    route: "/project/01DESDW646M02M8S8R9B4Y98W9/inventory-sheet/upload"
  });

  expect(container).toBeTruthy();
});
