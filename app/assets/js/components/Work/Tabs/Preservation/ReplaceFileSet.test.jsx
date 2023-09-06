import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";

import { AuthProvider } from "@js/components/Auth/Auth";
import { CodeListProvider } from "@js/context/code-list-context";
import React from "react";
import ReplaceFileSet from "@js/components/Work/Tabs/Preservation/ReplaceFileSet";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { getPresignedUrlForFileSetMock } from "@js/components/IngestSheet/ingestSheet.gql.mock";
import { mockWork } from "@js/components/Work/work.gql.mock.js";
import { screen } from "@testing-library/react";

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

describe("ReplaceFileSet component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(ReplaceFileSet, {
      closeModal: handleClose,
      fileset: mockWork.fileSets[0],
      isVisible: isModalOpen,
      workId: mockWork.id,
      workTypeId: mockWork.workType.id,
    });
    return renderWithRouterApollo(
      <AuthProvider>
        <CodeListProvider>
          <Wrapped />
        </CodeListProvider>
      </AuthProvider>,
      {
        mocks: [
          getPresignedUrlForFileSetMock,
          getCurrentUserMock,
          ...allCodeListMocks,
        ],
      }
    );
  });

  it("renders the replace fileset modal and form", async () => {
    expect(
      await screen.findByTestId("replace-fileset-modal")
    ).toBeInTheDocument();
    expect(
      await screen.findByTestId("replace-fileset-form")
    ).toBeInTheDocument();
  });

  it("renders a warning message and a button to replace the fileset", async () => {
    expect(
      await screen.findByText(/Replacing a fileset cannot be undone/i)
    ).toBeInTheDocument();
    expect(
      await screen.findByText(
        /Drag 'n' drop a file here, or click to select file/i
      )
    ).toBeInTheDocument();
  });
});
