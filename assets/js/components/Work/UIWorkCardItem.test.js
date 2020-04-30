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

describe("Shows Work content", () => {
  it("Displays Visibility Tag", () => {
    const { getByTestId, findByText } = setupTests();
    expect(getByTestId("tag-visibility")).toBeInTheDocument();
    expect(findByText("RESTRICTED")).toBeTruthy();
  });
  it("Displays Accession Number", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("dd-accession-number").innerHTML).toBe("Example-34");
  });
  it("Displays FileSets Length", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("dd-filesets-length").innerHTML).toBe("2");
  });
  it("Displays Updated Date", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("dd-updated-date").innerHTML).toBe(
      "Dec 2, 2019 10:22 PM"
    );
  });
  it("Displays Published Flad", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("dd-published").innerHTML).toBe("False");
  });
});
