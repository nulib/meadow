import React from "react";
import {
  mockWork,
  renderWithRouterApollo,
} from "../../../services/testing-helpers";
import WorkTabsAbout from "./About";
import { fireEvent } from "@testing-library/react";

import { CODE_LIST_QUERY } from "../controlledVocabulary.query";

const mocks = [
  {
    request: {
      query: CODE_LIST_QUERY,
      variables: { scheme: "RIGHTS_STATEMENT" },
    },
    result: {
      data: {
        codeList: [
          {
            id: "http://rightsstatements.org/vocab/InC/1.0/",
            label: "In Copyright",
            __typename: "CodedTerm",
          },
          {
            id: "http://rightsstatements.org/vocab/InC-OW-EU/1.0/",
            label: "In Copyright - EU Orphan Work",
            __typename: "CodedTerm",
          },
          {
            id: " http://rightsstatements.org/vocab/InC-EDU/1.0/",
            label: "In Copyright - Educational Use Permitted",
          },
        ],
      },
    },
  },
];

describe("Work About tab component", () => {
  function setupTests() {
    return renderWithRouterApollo(<WorkTabsAbout work={mockWork} />, { mocks });
  }
  it("renders without crashing", () => {
    expect(setupTests());
  });

  it("switches between edit and non edit mode ", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("edit-button")).toBeInTheDocument();

    fireEvent.click(getByTestId("edit-button"));
    expect(getByTestId("save-button")).toBeInTheDocument();
    expect(getByTestId("cancel-button")).toBeInTheDocument();
  });

  it("displays form elements only when in edit mode", () => {
    const { queryByTestId } = setupTests();

    expect(queryByTestId("description")).toBeFalsy();
    expect(queryByTestId("date-created")).toBeFalsy();

    fireEvent.click(queryByTestId("edit-button"));
    expect(queryByTestId("description")).toBeInTheDocument();
    expect(queryByTestId("date-created")).toBeInTheDocument();
  });

  it("dislays correct work item metadata values", () => {
    const { getByText, getByTestId, getByDisplayValue } = setupTests();

    expect(getByText(/Ima description/i)).toBeInTheDocument();

    // And ensure the values transfer to the form elements when in edit mode
    fireEvent.click(getByTestId("edit-button"));
    expect(getByDisplayValue(/ima description/i)).toBeInTheDocument();
  });
});
