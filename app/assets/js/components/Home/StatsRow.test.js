import React from "react";
import { render, screen } from "@testing-library/react";
import HomeStatsRow from "@js/components/Home/StatsRow";

export const mockStats = [
  {
    heading: "Collections",
    title: 12933,
  },
  {
    heading: "Works",
    title: 986324532,
  },
  {
    heading: "Works Published",
    title: 238844,
  },
];

describe("HomeStatsRow component", () => {
  beforeEach(() => {
    render(<HomeStatsRow stats={mockStats} />);
  });

  it("renders without crashing", () => {
    expect(screen.getByTestId("stats-row"));
  });

  it("renders the Collection stat", () => {
    expect(screen.getByText("Collections"));
  });

  it("renders the Works stat", () => {
    expect(screen.getByText("Works"));
  });

  it("renders the percentage of Works published stat", () => {});
});
