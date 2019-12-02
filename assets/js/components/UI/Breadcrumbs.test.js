import React from "react";
import { render } from "@testing-library/react";
import { renderWithRouter } from "../../testing-helpers";
import Breadcrumbs from "./Breadcrumbs";

const crumbs = [
  {
    label: "Projects",
    link: "/project/list"
  },
  {
    label: "Sub project",
    link: "/project/list/subproject"
  },
  {
    label: "Ima third",
    link: "/any/thing",
    labelWithoutLink: "Sheet:"
  }
];

describe("Breadcrumbs component", () => {
  function setUpTests() {
    return renderWithRouter(<Breadcrumbs crumbs={crumbs} />);
  }

  it("renders the component", () => {
    expect(render(<Breadcrumbs />));
  });

  it("renders the breadcrumb list and the correct number of breadcrumbs", () => {
    const { getByTestId, debug } = setUpTests();
    const ulEl = getByTestId("breadcrumbs");
    expect(ulEl).toBeInTheDocument();
    expect(ulEl.querySelectorAll("li")).toHaveLength(3);
  });

  it("renders the correct breadcrumb info, text, and text links", () => {
    const { getByTestId } = setUpTests();
    const ulEl = getByTestId("breadcrumbs");

    // Renders a link with correct label
    expect(ulEl.children[1].querySelector("a").innerHTML).toEqual(
      crumbs[1].label
    );

    // Displays non link text alongside linked text
    const liEl = ulEl.children[2];
    expect(liEl.textContent).toEqual(
      `${crumbs[2].labelWithoutLink}${crumbs[2].label}`
    );

    // Displays the proper hyperlink and label
    const aEl = liEl.querySelector("a");
    expect(aEl.getAttribute("href")).toEqual(crumbs[2].link);
    expect(aEl.innerHTML).toEqual(crumbs[2].label);
  });
});
