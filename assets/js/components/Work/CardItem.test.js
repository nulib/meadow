import React from "react";
import WorkCardItem from "./CardItem";
import { renderWithRouter } from "../../services/testing-helpers";
import { mockWork as work } from "./work.gql.mock";

const workObject = {
  id: work.id,
  representativeImage: work.representativeImage,
  title: work.title,
  workType: work.workType,
  visibility: work.visibility,
  published: work.published,
  accessionNumber: work.accessionNumber,
  fileSets: work.fileSets.length,
  manifestUrl: work.manifestUrl,
  updatedAt: work.updatedAt,
};

function setupTests() {
  return renderWithRouter(<WorkCardItem {...workObject} />);
}

it("Displays Work card", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-workcard")).toBeInTheDocument();
});

it("Displays Representative Image for Work", () => {
  const { getByTestId, debug } = setupTests();
  const el = getByTestId("image-work");
  expect(el.getAttribute("src")).toEqual(
    "http://foobar/full/1280,960/0/default.jpg"
  );
});

describe("Shows Work content", () => {
  it("Displays Visibility Tag", () => {
    const { getByTestId, findByText } = setupTests();
    expect(getByTestId("tag-visibility")).toBeInTheDocument();
    expect(findByText("PUBLIC")).toBeTruthy();
  });

  it("Displays Collection Name", () => {
    const { findByText } = setupTests();
    expect(findByText("Collection 1232432 Name")).toBeTruthy();
  });

  it("Displays Published Flag", () => {
    const { queryByTestId } = setupTests();
    expect(queryByTestId("result-item-published")).not.toBeInTheDocument();
  });
});
