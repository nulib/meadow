import React from "react";
import { render, queryByText } from "@testing-library/react";
import UICodedTermItem from "./Item";

describe("UIControlledVocabList", () => {
  it("renders without crashing", () => {
    const { getByTestId } = render(<UICodedTermItem />);
  });

  it("renders display value only if id and label passed in", () => {
    const item1 = render(
      <UICodedTermItem item={{ label: "Ima label", id: "" }} />
    );
    expect(item1.queryByText("Ima label")).toBeNull();

    const item2 = render(
      <UICodedTermItem item={{ label: "Ima label", id: "ABC123" }} />
    );
    expect(item2.queryByText("Ima label"));
  });
});
