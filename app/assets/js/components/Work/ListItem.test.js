import React from "react";
import WorkListItem from "./ListItem";
import { mockWork } from "./work.gql.mock";
import { renderWithRouter } from "@js/services/testing-helpers";
import { prepWorkItemForDisplay } from "@js/services/helpers";

function setupTests() {
  return renderWithRouter(
    <WorkListItem {...prepWorkItemForDisplay(mockWork)} id={mockWork.id} />
  );
}

it("Displays Work List Item", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-worklist-item")).toBeInTheDocument();
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
  it("Displays Published Flag", () => {
    const { queryByTestId } = setupTests();
    expect(queryByTestId("result-item-published")).not.toBeInTheDocument();
  });
});
