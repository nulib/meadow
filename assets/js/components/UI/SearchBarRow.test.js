import React from "react";
import { screen, render } from "@testing-library/react";
import UISearchBarRow from "@js/components/UI/SearchBarRow";

describe("UISearchBarRow component", () => {
  beforeEach(() => {
    render(
      <UISearchBarRow>
        <div>Foobar</div>
      </UISearchBarRow>
    );
  });

  it("renders main components", () => {
    expect(screen.getByTestId("search-bar-row"));
    expect(screen.getByTestId("icon-search"));
  });

  it("renders child content", () => {
    expect(screen.getByText("Foobar"));
  });
});
