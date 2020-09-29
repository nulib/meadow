import React from "react";
import { screen, render } from "@testing-library/react";
import UIFacetLink from "./FacetLink";

let item = {
  term: {
    id: "http://vocab.getty.edu/aat/300026031",
    label: "document genres",
  },
};

describe("UIFacetLink component", () => {
  it("renders faceted label as a link", () => {
    render(<UIFacetLink facetComponentId="Genre" item={item} />);
    expect(screen.getByTestId("facet-link"));
    expect(document.querySelector("a")).toHaveTextContent(item.term.label);
  });

  it("renders faceted label plus role if the facet item contains a role", () => {
    let itemWithRole = {
      ...item,
      role: {
        id: "mrb",
        label: "Marbler",
        scheme: "MARC_RELATOR",
      },
    };
    render(<UIFacetLink facetComponentId="Genre" item={itemWithRole} />);
    expect(screen.getByText(`${item.term.label} (${itemWithRole.role.label})`));
  });
});
