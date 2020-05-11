import React from "react";
import { render } from "@testing-library/react";
import UIControlledTermList from "./List";

describe("UIControlledVocabList", () => {
  it("renders UIControlledTermList", () => {
    const { getByTestId } = render(<UIControlledTermList />);
    expect(getByTestId("controlled-term-list"));
  });

  // TODO: fill these out
});
