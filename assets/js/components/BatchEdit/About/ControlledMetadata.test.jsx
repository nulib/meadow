import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../services/testing-helpers";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import {
  codeListMarcRelatorMock,
  codeListAuthorityMock,
  codeListSubjectRoleMock,
  marcRelatorMock,
  authorityMock,
  subjectMock,
} from "../../Work/controlledVocabulary.gql.mock";
import { CONTROLLED_METADATA } from "../../../services/metadata";
import { BatchProvider } from "../../../context/batch-edit-context";

describe("BatchEditAboutCoreMetadata component", () => {
  function prepLocalStorage() {
    localStorage.setItem(
      "codeLists",
      JSON.stringify({
        MARC_RELATOR: marcRelatorMock,
        AUTHORITY: authorityMock,
        SUBJECT_ROLE: subjectMock,
      })
    );
  }
  function setupTest() {
    //prepLocalStorage();
    const Wrapped = withReactHookFormControl(BatchEditAboutControlledMetadata);

    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <Wrapped />
      </BatchProvider>,
      {
        mocks: [
          codeListMarcRelatorMock,
          codeListAuthorityMock,
          codeListSubjectRoleMock,
        ],
      }
    );
  }
  it("renders controlled metadata component", async () => {
    let { queryByTestId } = setupTest();
    await waitFor(() => {
      expect(queryByTestId("controlled-metadata")).toBeInTheDocument();
    });
  });
  it("renders expected controlled metadata fields", async () => {
    let { getByTestId } = setupTest();
    await waitFor(() => {
      for (let item of CONTROLLED_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
});
