import React from "react";
import WorkListItem from "./ListItem";
import { mockWork as work } from "./work.gql.mock";
import { renderWithRouter } from "../../services/testing-helpers";

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
  return renderWithRouter(<WorkListItem {...workObject} />);
}

it("Displays Work List Item", () => {
  const { getByTestId, debug } = setupTests();
  expect(getByTestId("ui-worklist-item")).toBeInTheDocument();
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
  it("Displays Accession Number", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("result-item-accession-number").innerHTML).toBe(
      "Donohue_001"
    );
  });
  it("Displays FileSets Length", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("result-item-filesets-length").innerHTML).toBe("4");
  });
  it("Displays Updated Date", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("result-item-updated-date").innerHTML).toBe(
      "Dec 2, 2019 10:22 PM"
    );
  });
  it("Displays Published Flag", () => {
    const { queryByTestId } = setupTests();
    expect(queryByTestId("result-item-published")).not.toBeInTheDocument();
  });
});
