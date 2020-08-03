import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../services/testing-helpers";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import {
  codeListSubjectRoleMock,
  codeListMarcRelatorMock,
  codeListAuthorityMock,
} from "../../Work/controlledVocabulary.gql.mock";
import { CONTROLLED_METADATA } from "../../../services/metadata";

describe("BatchEditAboutCoreMetadata component", () => {
  function setupTest() {
    const Wrapped = withReactHookFormControl(BatchEditAboutControlledMetadata);

    return renderWithRouterApollo(<Wrapped />, {
      mocks: [
        codeListMarcRelatorMock,
        codeListAuthorityMock,
        codeListSubjectRoleMock,
      ],
    });
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
