import React from "react";
import WorkCardItem from "./CardItem";
import { renderWithRouter } from "@js/services/testing-helpers";
import { mockWork } from "./work.gql.mock";
import { prepWorkItemForDisplay } from "@js/services/helpers";

function setupTests() {
  return renderWithRouter(
    <WorkCardItem {...prepWorkItemForDisplay(mockWork)} id={mockWork.id} />
  );
}

it("Displays Work card", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-workcard")).toBeInTheDocument();
});

describe("Shows Work content", () => {
  it("Displays Visibility Tag", () => {
    const { getByTestId, findByText } = setupTests();
    expect(getByTestId("tag-visibility")).toBeInTheDocument();
    expect(findByText("PUBLIC")).toBeTruthy();
  });

  it("Displays Collection Name", () => {
    const { findByText } = setupTests();
    expect(findByText("Collection 1232432 Name")).toBeTruthy();
  });

  it("Displays Accession Number", () => {
    const { findByText } = setupTests();
    expect(findByText("Donohue_001")).toBeTruthy();
  });

  it("Displays Published Flag", () => {
    const { queryByTestId } = setupTests();
    expect(queryByTestId("result-item-published")).not.toBeInTheDocument();
  });
});
