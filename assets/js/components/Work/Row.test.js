import React from "react";
import WorkRow from "./Row";
import { renderWithRouter } from "../../services/testing-helpers";

const work = {
  accessionNumber: "Example-34",
  fileSets: [
    {
      accessionNumber: "Example-34-3",
      id: "01DV4BAEAGKNT5P3GH10X263K1",
      coreMetadata: {
        description: "Lorem Ipsum",
      },
      work: {
        id: "01DV4BAE9NDQHSMRHKM8KC4FNC",
      },
    },
    {
      accessionNumber: "Example-34-4",
      id: "01DV4BAEANHGYQKQ2EPBWJVJSR",
      coreMetadata: {
        description: "Lorem Ipsum",
      },
      work: {
        id: "01DV4BAE9NDQHSMRHKM8KC4FNC",
      },
    },
  ],
  id: "01DV4BAE9NDQHSMRHKM8KC4FNC",
  insertedAt: "2019-12-02T22:22:30",
  coreMetadata: {
    title: null,
  },
  updatedAt: "2019-12-02T22:22:30",
};

describe("WorkRow component", () => {
  it("renders without crashing", () => {
    expect(renderWithRouter(<WorkRow work={work} />)).toBeTruthy();
  });

  it("renders the work row element", () => {
    const { getByTestId } = renderWithRouter(<WorkRow work={work} />);
    expect(getByTestId("work-row")).toBeInTheDocument();
  });
});
