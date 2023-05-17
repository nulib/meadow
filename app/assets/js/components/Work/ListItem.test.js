import React from "react";
import WorkListItem from "./ListItem";
import { indexWork } from "@js/mock-data/elasticsearch-response";
import { prepWorkItemForDisplay } from "@js/services/helpers";
import { renderWithRouter } from "@js/services/testing-helpers";

function setupTests() {
  return renderWithRouter(
    <WorkListItem {...prepWorkItemForDisplay(indexWork)} id={indexWork.id} />
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
  it("Displays Tags", () => {
    const { getByText } = setupTests();
    expect(getByText(/image/i)).toBeInTheDocument();
    expect(getByText(/published/i)).toBeInTheDocument();
    expect(getByText(/private/i)).toBeInTheDocument();
  });
});
