import React from "react";
import { render, screen } from "@testing-library/react";
import UIFormFieldArrayDisplay from "./FieldArrayDisplay";

const values = ["Metadata item #1", "Metadata item #2", "Metadata item #3"];
const props = {
  values,
  isFacetLink: false,
  metadataItem: {
    name: "boxNumber",
    facetComponentId: "BoxNumber",
    label: "Box Number",
    metadataClass: "descriptive",
  },
};

describe("UIFormFieldArrayDisplay", () => {
  it("renders the label", () => {
    const { getByTestId } = render(<UIFormFieldArrayDisplay {...props} />);
    expect(getByTestId("items-label"));
  });

  it("renders an expected list of metadata values", () => {
    const { getByTestId, getByText } = render(
      <UIFormFieldArrayDisplay {...props} />
    );
    const listEl = getByTestId("field-array-item-list");
    expect(listEl);
    expect(listEl.children).toHaveLength(3);
    expect(getByText("Metadata item #1"));
    expect(getByText("Metadata item #2"));
    expect(getByText("Metadata item #3"));
  });

  it("does not render a link by default", () => {
    render(<UIFormFieldArrayDisplay {...props} isFacetLink={false} />);
    expect(screen.getByText("Metadata item #1").nodeName).toEqual("LI");
  });

  it("renders the item as a link if configured", () => {
    render(<UIFormFieldArrayDisplay {...props} isFacetLink={true} />);
    expect(screen.getByText("Metadata item #1").nodeName).toEqual("A");
  });
});
