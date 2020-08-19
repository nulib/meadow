import React from "react";
import WorkListItem from "./ListItem";
import { mockWork } from "./work.gql.mock";
import { renderWithRouter } from "../../services/testing-helpers";
import { prepWorkItemForDisplay } from "../../services/helpers";

function setupTests() {
  return renderWithRouter(
    <WorkListItem {...prepWorkItemForDisplay(mockWork)} id={mockWork.id} />
  );
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

describe("Shows Work content", () => {
  it("Displays Visibility Tag", () => {
    const { getByTestId, findByText } = setupTests();
    expect(getByTestId("tag-visibility")).toBeInTheDocument();
    expect(findByText("PUBLIC")).toBeTruthy();
  });
  it("Displays Accession Number", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("result-item-accession-number").innerHTML).toBe(
      "Donohue_001"
    );
  });
  it("Displays FileSets Length", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("result-item-filesets-length").innerHTML).toBe("4");
  });
  it("Displays Updated Date", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("result-item-updated-date").innerHTML).toBe(
      "Dec 2, 2019 10:22 PM"
    );
  });
  it("Displays Published Flag", () => {
    const { queryByTestId } = setupTests();
    expect(queryByTestId("result-item-published")).not.toBeInTheDocument();
  });
});
