import React from "react";
import { render } from "@testing-library/react";
import UIFormFieldArrayDisplay from "./FieldArrayDisplay";

const items = ["Metadata item #1", "Metadata item #2", "Metadata item #3"];

describe("UIFormFieldArrayDisplay", () => {
  it("renders the label", () => {
    const { getByTestId } = render(
      <UIFormFieldArrayDisplay items={items} label="Field Array Items" />
    );
    expect(getByTestId("items-label"));
  });

  it("renders an expected list of metadata items", () => {
    const { getByTestId, getByText } = render(
      <UIFormFieldArrayDisplay items={items} label="Field Array Items" />
    );
    const listEl = getByTestId("field-array-item-list");
    expect(listEl);
    expect(listEl.children).toHaveLength(3);
    expect(getByText("Metadata item #1"));
    expect(getByText("Metadata item #2"));
    expect(getByText("Metadata item #3"));
  });
});
