import React from "react";
import { renderWithRouterApollo } from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutControlledMetadata from "./ControlledMetadata";
import { waitFor } from "@testing-library/react";
import {
  codeListAuthorityMock,
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
} from "../../controlledVocabulary.gql.mock";

describe("Work About tab Controlled Metadata component", () => {
  function setupTests() {
    return renderWithRouterApollo(
      <WorkTabsAboutControlledMetadata
        descriptiveMetadata={mockWork.descriptiveMetadata}
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

  it("renders controlled metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("controlled-metadata")).toBeInTheDocument();
    });
  });
});
