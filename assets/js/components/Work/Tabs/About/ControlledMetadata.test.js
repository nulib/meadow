import React from "react";
import { renderWithRouterApollo } from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutControlledMetadata from "./ControlledMetadata";
import { waitFor } from "@testing-library/react";
import { CodeListProvider } from "@js/context/code-list-context";
import {
  codeListAuthorityMock,
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
} from "@js/components/Work/controlledVocabulary.gql.mock";

describe("Work About tab Controlled Metadata component", () => {
  function setupTests() {
    return renderWithRouterApollo(
      <CodeListProvider>
        <WorkTabsAboutControlledMetadata
          descriptiveMetadata={mockWork.descriptiveMetadata}
        />
      </CodeListProvider>,
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
