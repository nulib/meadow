import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import userEvent from "@testing-library/user-event";
import { WorkProvider } from "@js/context/work-context";
import WorkFilesetActionButtonsGroupAdd from "./GroupAdd";

const mockUpdateFileSetFn = jest.fn();

const fileSet = mockFileSets[0];
const candidateFileSets = [mockFileSets[1], mockFileSets[2]];

describe("WorkFilesetActionButtonsGroupAdd component", () => {
  beforeEach(() => {
    render(
      <WorkProvider>
        <WorkFilesetActionButtonsGroupAdd
          fileSetId={fileSet.id}
          candidateFileSets={candidateFileSets}
          handleUpdateFileSet={mockUpdateFileSetFn}
          iiifServerUrl="http://example.org/iiif/"
        />
      </WorkProvider>,
    );
  });

  it("renders the FileSet GroupAdd component", async () => {
    const groupAdd = await screen.findByTestId("fileset-group-add");
    expect(groupAdd).toBeInTheDocument();

    // renders and input
    const input = groupAdd.querySelector("input");
    expect(input.getAttribute("placeholder")).toBe("Attach filesets...");

    // renders the searchbox expanded as false
    const searchbox = groupAdd.querySelector("div[role='searchbox']");
    expect(searchbox.getAttribute("aria-expanded")).toBe("false");

    // children of the collapsed searchbox are not rendered
    const buttons = searchbox.querySelectorAll("button");
    expect(buttons).toHaveLength(0);
  });

  it("renders the handles user interactions", async () => {
    const groupAdd = await screen.findByTestId("fileset-group-add");
    const input = groupAdd.querySelector("input");
    const searchbox = groupAdd.querySelector("div[role='searchbox']");

    // focus the input and type
    const user = userEvent.setup();
    await user.click(input);

    // expands the searchbox on focus
    expect(searchbox.getAttribute("aria-expanded")).toBe("true");

    // children of the expanded searchbox are buttons and rendered
    const buttons = groupAdd.querySelectorAll("button");
    expect(buttons).toHaveLength(2);

    // renders candidate options
    const candidatesDefaultState = await screen.findAllByTestId(
      "fileset-group-add-candidate",
    );
    expect(candidatesDefaultState).toHaveLength(2);

    // users types in the input to filter
    await user.type(input, "2572813");
    const candidatesFiltered = await screen.findAllByTestId(
      "fileset-group-add-candidate",
    );
    expect(candidatesFiltered).toHaveLength(1);

    const filteredCandidate = candidatesFiltered[0];
    expect(filteredCandidate).toHaveTextContent(
      "inu-dil-41913a91-037f-494b-9113-06004a8a98fb.jpg",
    );
    expect(filteredCandidate).toHaveTextContent("Voyager:2572813_FILE_0");
    expect(filteredCandidate.querySelector("img")).toHaveAttribute(
      "src",
      "http://example.org/iiif/109b9a5c-3c6f-4a98-b98b-12402b871dc7/square/32,32/0/default.jpg",
    );

    // click the candidate to add
    await user.click(filteredCandidate);
    expect(mockUpdateFileSetFn).toHaveBeenCalledWith(
      "109b9a5c-3c6f-4a98-b98b-12402b871dc7",
      fileSet.id,
    );
  });

  it("renders message if no applicable candidates are found", async () => {
    const groupAdd = await screen.findByTestId("fileset-group-add");
    const input = groupAdd.querySelector("input");
    const searchbox = groupAdd.querySelector("div[role='searchbox']");

    // focus the input and type
    const user = userEvent.setup();
    await user.click(input);

    // renders searchbox expanded, with 0 candidates, and a message
    await user.type(input, "foo bar");
    await waitFor(() => {
      expect(
        screen.queryAllByTestId("fileset-group-add-candidate"),
      ).toHaveLength(0);
    });
    expect(searchbox).toHaveTextContent("Applicable fileset(s) not found.");
  });
});
