import React from "react";
import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, mock } from "bun:test";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { GET_COLLECTIONS } from "@js/components/Collection/collection.gql";
import FileSetPicker from "./FileSetPicker";
import { GET_TRANSCRIBABLE_FILE_SETS } from "./transcription.gql";

const fileSet = (n: number) => ({
  id: `file-set-${n}`,
  accessionNumber: `ACC_${n}`,
  label: `Page ${n}`,
  representativeImageUrl: `https://iiif.example.edu/iiif/3/file-set-${n}`,
  workId: "work-1",
  workTitle: "A scrapbook",
  workAccessionNumber: "WORK_1",
  collectionId: "collection-1",
  collectionTitle: "Scrapbooks",
});

const mocks = [
  {
    request: { query: GET_COLLECTIONS },
    result: { data: { collections: [] } },
  },
  {
    request: {
      query: GET_TRANSCRIBABLE_FILE_SETS,
      variables: { limit: 10, offset: 0, collectionId: null, work: null },
    },
    result: {
      data: {
        transcribableFileSets: {
          total: 12,
          fileSets: [fileSet(1), fileSet(2)],
        },
      },
    },
  },
];

describe("transcription bench FileSetPicker", () => {
  it("lists a page of file sets and ticks one", async () => {
    const onChange = mock(() => {});
    renderWithRouterApollo(
      <FileSetPicker selected={[]} onChange={onChange} />,
      {
        mocks,
      },
    );

    expect(await screen.findByText("Page 1")).toBeInTheDocument();
    expect(screen.getByText("1–10 of 12")).toBeInTheDocument();
    expect(screen.getByText("Selected (0)")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Previous" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Next" })).not.toBeDisabled();

    await userEvent.click(screen.getByLabelText("Transcribe Page 2"));
    expect(onChange).toHaveBeenCalledWith([
      {
        id: "file-set-2",
        label: "Page 2",
        thumbnail:
          "https://iiif.example.edu/iiif/3/file-set-2/square/128,128/0/default.jpg",
      },
    ]);
  });

  it("shows what is selected, from any page, and removes it", async () => {
    const onChange = mock(() => {});
    const picked = { id: "elsewhere", label: "Another page", thumbnail: null };
    renderWithRouterApollo(
      <FileSetPicker selected={[picked]} onChange={onChange} />,
      { mocks },
    );

    expect(await screen.findByText("Selected (1)")).toBeInTheDocument();
    await userEvent.click(screen.getByLabelText("Remove Another page"));
    expect(onChange).toHaveBeenCalledWith([]);
  });
});
