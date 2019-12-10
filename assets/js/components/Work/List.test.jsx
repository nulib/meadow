import React from "react";
import WorkList from "./List";
import { render } from "@testing-library/react";
import { renderWithRouter } from "../../testing-helpers";

const works = [
  {
    accessionNumber: "Example-34",
    fileSets: [
      {
        accessionNumber: "Example-34-3",
        id: "01DV4BAEAGKNT5P3GH10X263K1",
        metadata: {
          description: "Lorem Ipsum"
        },
        work: {
          id: "01DV4BAE9NDQHSMRHKM8KC4FNC"
        }
      }
    ],
    id: "01DV4BAE9NDQHSMRHKM8KC4FNC",
    insertedAt: "2019-12-02T22:22:30",
    metadata: {
      title: null
    },
    updatedAt: "2019-12-02T22:22:30",
    visibility: "RESTRICTED",
    workType: "IMAGE"
  },
  {
    accessionNumber: "Example-30",
    id: "01DV4BAEC14Q87NRGMY9RX08FE",
    insertedAt: "2019-12-02T22:22:30",
    metadata: {
      title: null
    },
    updatedAt: "2019-12-02T22:22:30",
    visibility: "RESTRICTED",
    workType: "IMAGE"
  }
];

describe("WorkList component", () => {
  it("renders without crashing", () => {
    expect(render(<WorkList />)).toBeTruthy();
  });

  it("renders the WorkList component only if works are present", () => {
    const { queryByTestId } = render(<WorkList />);
    expect(queryByTestId("work-list")).not.toBeInTheDocument();

    const { getByTestId } = renderWithRouter(<WorkList works={works} />);
    expect(getByTestId("work-list")).toBeInTheDocument();
  });
});
