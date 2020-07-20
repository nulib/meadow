import React from "react";
import BatchEditAboutDescriptiveMetadata from "./DescriptiveMetadata";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import {
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
  codeListAuthorityMock,
} from "../../Work/controlledVocabulary.gql.mock";

const registerMock = jest.fn();

describe("BatchEditAboutDescriptiveMetadata component", () => {
  function setupTest() {
    return renderWithRouterApollo(
      <BatchEditAboutDescriptiveMetadata
        register={registerMock}
        control={{}}
      />,
      {
        mocks: [
          codeListAuthorityMock,
          codeListMarcRelatorMock,
          codeListSubjectRoleMock,
        ],
      }
    );
  }
  xit("renders the component", async () => {
    let { queryByTestId, debug } = setupTest();

    await waitFor(() => {
      expect(queryByTestId("descriptive-metadata")).toBeInTheDocument();
    });
  });
});
