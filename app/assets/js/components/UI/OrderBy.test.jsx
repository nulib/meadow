import React from "react";
import UIOrderBy from "./OrderBy";
import { render, screen } from "@testing-library/react";

describe("UIOrderBy", () => {
  it("renders active order by link with asc", () => {
    render(
      <UIOrderBy
        label="Date"
        columnName="date"
        orderedFileSets={{
          order: "asc",
          orderBy: "date",
          orderedFileSets: [],
        }}
      />,
    );

    const link = screen.getByRole("link");
    expect(link).toHaveTextContent("Date");
    expect(link).toHaveStyle("font-weight: 700");

    const icon = link.querySelector("svg");
    expect(icon.dataset["sort"]).toBe("asc");
  });

  it("renders active order by link with desc", () => {
    render(
      <UIOrderBy
        label="Date"
        columnName="date"
        orderedFileSets={{
          order: "desc",
          orderBy: "date",
          orderedFileSets: [],
        }}
      />,
    );

    const link = screen.getByRole("link");
    expect(link).toHaveTextContent("Date");
    expect(link).toHaveStyle("font-weight: 700");

    const icon = link.querySelector("svg");
    expect(icon.dataset["sort"]).toBe("desc");
  });

  it("renders an inactive order by link", () => {
    render(
      <UIOrderBy
        label="Date"
        columnName="date"
        orderedFileSets={{
          order: "asc",
          orderBy: "location",
          orderedFileSets: [],
        }}
      />,
    );

    const link = screen.getByRole("link");
    expect(link).toHaveTextContent("Date");
    expect(link).toHaveStyle("font-weight: 400");

    const icon = link.querySelector("svg");
    expect(icon.dataset["sort"]).toBe("");
  });

  it("handles the onClickCallback correctly", () => {
    const onClickCallback = jest.fn();

    render(
      <UIOrderBy
        label="Date"
        columnName="date"
        orderedFileSets={{
          order: "asc",
          orderBy: "date",
          orderedFileSets: [],
        }}
        onClickCallback={onClickCallback}
      />,
    );

    screen.getByRole("link").click();

    expect(onClickCallback).toHaveBeenCalledTimes(1);
    expect(onClickCallback).toHaveBeenCalledWith({
      order: "desc",
      orderBy: "date",
    });
  });
});
