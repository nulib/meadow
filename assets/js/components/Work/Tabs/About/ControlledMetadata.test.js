import React from "react";
import { renderWithRouterApollo } from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutControlledMetadata from "./ControlledMetadata";
import { waitFor } from "@testing-library/react";
import {
  marcRelatorMock,
  authorityMock,
  subjectMock,
} from "../../controlledVocabulary.gql.mock";
import { LOCAL_STORAGE_CODELIST_KEY } from "../../../../services/global-vars";

describe("Work About tab Controlled Metadata component", () => {
  function prepLocalStorage() {
    localStorage.setItem(
      LOCAL_STORAGE_CODELIST_KEY,
      JSON.stringify({
        MARC_RELATOR: marcRelatorMock,
        AUTHORITY: authorityMock,
        SUBJECT_ROLE: subjectMock,
      })
    );
  }
  function setupTests() {
    prepLocalStorage();
    return renderWithRouterApollo(
      <WorkTabsAboutControlledMetadata
        descriptiveMetadata={mockWork.descriptiveMetadata}
      />
    );
  }

  it("renders controlled metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("controlled-metadata")).toBeInTheDocument();
    });
  });
});
