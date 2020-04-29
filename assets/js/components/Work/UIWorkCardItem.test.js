import React from "react";
import UIWorkCardItem from "./UIWorkCardItem";
import { mockWork } from "../../services/testing-helpers";
import { renderWithRouter } from "../../services/testing-helpers";

function setupTests() {
  return renderWithRouter(<UIWorkCardItem work={mockWork} />);
}

it("Displays Work card", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-workcard")).toBeInTheDocument();
});

it("Displays Representative Image for Work", () => {
  const { getByTestId, debug } = setupTests();
  const el = getByTestId("image-work");
  expect(el.getAttribute("src")).toEqual(
    "http://foobar/full/1280,960/0/default.jpg"
  );
});

it("Displays Filesets for Work", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("fileset-01DV4BAEAGKNT5P3GH10X263K1")).toBeInTheDocument();
  expect(getByTestId("fileset-01DV4BAEANHGYQKQ2EPBWJVJSR")).toBeInTheDocument();
});

it("Displays Visibility tag", () => {
  const { getByTestId, findByText } = setupTests();
  expect(getByTestId("tag-visibility")).toBeInTheDocument();
  expect(findByText("RESTRICTED")).toBeTruthy();
});
