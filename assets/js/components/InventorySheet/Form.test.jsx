import React from "react";
import { render, fireEvent, cleanup } from "@testing-library/react";
import InventorySheetForm from "./Form";
import "@testing-library/jest-dom/extend-expect";
import { renderWithRouter } from "../../testing-helpers";

afterEach(cleanup);

const testFormId = "inventory-sheet-upload-form";

const handleSubmit = jest.fn();
const handleCancel = jest.fn();

test("InventorySheet upload form component renders", () => {
  const { container } = renderWithRouter(
    <InventorySheetForm
      handleSubmit={handleSubmit}
      handleCancel={handleCancel}
    />
  );
  expect(container).toBeTruthy();
});

test("Upload form is displayed", () => {
  const { queryByTestId } = renderWithRouter(
    <InventorySheetForm
      handleSubmit={handleSubmit}
      handleCancel={handleCancel}
    />
  );
  expect(queryByTestId(testFormId)).toBeVisible();
});

test("Submitting the form calls the parent function", () => {
  const { getByTestId } = renderWithRouter(
    <InventorySheetForm
      handleSubmit={handleSubmit}
      handleCancel={handleCancel}
    />,
    { route: "/inventory-sheet/upload" }
  );

  fireEvent.submit(getByTestId("inventory-sheet-upload-form"));
  expect(handleSubmit).toHaveBeenCalledTimes(1);
});
