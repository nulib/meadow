import React from "react";
import WorkCardItem from "./CardItem";
import { indexWork } from "@js/mock-data/elasticsearch-response";
import { prepWorkItemForDisplay } from "@js/services/helpers";
import { renderWithRouter } from "@js/services/testing-helpers";

function setupTests() {
  return renderWithRouter(
    <WorkCardItem {...prepWorkItemForDisplay(indexWork)} id={indexWork.id} />,
  );
}

it("Displays Work card", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-workcard")).toBeInTheDocument();
});

describe("Shows Work content", () => {
  it("Displays Visibility Tag", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("tag-visibility")).toBeInTheDocument();
    expect(getByTestId("tag-visibility")).toHaveTextContent("Private");
  });

  it("Displays Accession Number", async () => {
    const { findByText } = setupTests();
    expect(await findByText("Donohue_001")).toBeInTheDocument();
  });

  it("Displays Tags", () => {
    const { getByText } = setupTests();
    expect(getByText(/image/i)).toBeInTheDocument();
    expect(getByText(/published/i)).toBeInTheDocument();
    expect(getByText(/private/i)).toBeInTheDocument();
  });
});
