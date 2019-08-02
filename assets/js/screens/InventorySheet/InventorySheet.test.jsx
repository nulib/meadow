import React from "react";
import { render, fireEvent, cleanup } from "@testing-library/react";
import ScreensInventorySheet from "./InventorySheet";
import "@testing-library/jest-dom/extend-expect";
import { renderWithRouter } from "../../testing-helpers";

afterEach(cleanup);

xtest("InventorySheet component loads", () => {
  const { container } = renderWithRouter(<ScreensInventorySheet />);
  expect(container).toBeTruthy();
});
