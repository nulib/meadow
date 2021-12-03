import React from "react";
import { render, screen, within } from "@testing-library/react";
import BatchEditConfirmationTable from "@js/components/BatchEdit/ConfirmationTable";
import {
  marcRelatorMock,
  notesSchemeMock,
  relatedUrlSchemeMock,
  subjectMock,
} from "@js/components/Work/controlledVocabulary.gql.mock";

const props = {
  codeLists: {
    marcData: { codeList: marcRelatorMock },
    notesData: {codeList: notesSchemeMock},
    relatedUrlData: { codeList: relatedUrlSchemeMock },
    subjectRoleData: { codeList: subjectMock },
  },
  itemsObj: {
    contributor: [
      {
        term: "http://id.worldcat.org/fast/1204155",
        role: { id: "act", scheme: "MARC_RELATOR" },
        label: "United States",
      },
    ],
    alternateTitle: ["gggg"],
    notes: [
      { note: "asdfasf", type: { id: "GENERAL_NOTE", scheme: "NOTE_TYPE" } },
      {
        note: "gggggg",
        type: { id: "BIOGRAPHICAL_HISTORICAL_NOTE", scheme: "NOTE_TYPE" },
      },
    ],
  },
  type: "add",
};

describe("BatchEditConfirmationTable component", () => {
  beforeEach(() => {
    render(<BatchEditConfirmationTable {...props} />);
  });

  it("renders the table", () => {
    expect(screen.getByTestId("confirmation-table"));
  });

  it("renders table headers", () => {
    expect(screen.getByText("Metadata Field"));
    expect(screen.getByText("Value"));
  });

  it("renders general data passed in", () => {
    const td = screen.getByText(/contributor/i);
    const row = td.closest("tr");
    const utils = within(row);
    expect(
      utils.getByText(
        "United States | http://id.worldcat.org/fast/1204155 | Actor"
      )
    );
  });
});
