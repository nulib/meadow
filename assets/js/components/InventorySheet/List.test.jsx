import React from "react";
import { render, cleanup } from "@testing-library/react";
import InventorySheetList from "./List";
import "@testing-library/jest-dom/extend-expect";
import { InventorySheets } from "../../mock-data/inventorySheets";
import { renderWithRouter } from "../../testing-helpers";

const projectId = "abcdefg123";

afterEach(cleanup);

xtest("InventorySheetList component renders", () => {
  const { container } = renderWithRouter(
    <InventorySheetList projectId={projectId} />
  );
  expect(container).toBeTruthy();
});

xtest("Displays a message that no sheets exist", () => {
  const { queryByTestId } = render(
    <InventorySheetList projectId={projectId} />
  );
  expect(queryByTestId("no-inventory-sheets-notification")).toBeVisible();
});

xtest("Displays a list of inventory sheets", () => {
  const { queryByTestId } = render(
    <InventorySheetList projectId={projectId} />
  );
  expect(queryByTestId("inventory-sheet-list")).toBeVisible();
});
