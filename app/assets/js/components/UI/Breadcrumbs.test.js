import React from "react";
import { render } from "@testing-library/react";
import { renderWithRouter } from "../../services/testing-helpers";
import Breadcrumbs from "./Breadcrumbs";

const crumbs = [
  {
    label: "Projects",
    route: "/project/list"
  },
  {
    label: "Sub project",
    route: "/project/list/subproject"
  },
  {
    label: "Ima third",
    route: "/any/thing",
    isActive: true
  }
];

describe("Breadcrumbs component", () => {
  function setUpTests() {
    return renderWithRouter(<Breadcrumbs items={crumbs} />);
  }

  it("renders the component", () => {
    expect(render(<Breadcrumbs />));
  });

  it("renders the breadcrumb list and the correct number of breadcrumbs", () => {
    const { getByTestId, debug } = setUpTests();
    const el = getByTestId("breadcrumbs");

    expect(el).toBeInTheDocument();
    expect(el.querySelectorAll("li")).toHaveLength(3);
  });

  it("renders the correct breadcrumb info, text, and text links", () => {
    const { getByTestId } = setUpTests();
    const el = getByTestId("breadcrumbs");
    const anchorEls = el.querySelectorAll("a");

    // Renders a link with correct label
    expect(anchorEls[1].innerHTML).toEqual(crumbs[1].label);

    // Displays the proper hyperlink and label
    expect(anchorEls[0].getAttribute("href")).toEqual(crumbs[0].route);
    expect(anchorEls[2].innerHTML).toEqual(crumbs[2].label);
  });
});
