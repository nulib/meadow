import React from "react";
import UIWorkListItem from "./UIWorkListItem";
import { mockWork } from "../../services/testing-helpers";
import { renderWithRouter } from "../../services/testing-helpers";

function setupTests() {
  return renderWithRouter(<UIWorkListItem work={mockWork} />);
}

it("Displays Work List Item", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-worklist-item")).toBeInTheDocument();
});

it("Displays Representative Image for Work", () => {
  const { getByTestId, debug } = setupTests();
  const el = getByTestId("image-work");
  expect(el.getAttribute("src")).toEqual(
    "http://foobar/full/1280,960/0/default.jpg"
  );
});

it("Displays Visibility tag", () => {
  const { getByTestId, findByText } = setupTests();
  expect(getByTestId("tag-visibility")).toBeInTheDocument();
  expect(findByText("RESTRICTED")).toBeTruthy();
});
