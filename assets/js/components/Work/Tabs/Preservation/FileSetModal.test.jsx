import React from "react";
import FileSetModal from "./FileSetModal";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getPresignedUrlForFileSetMock } from "@js/components/IngestSheet/ingestSheet.gql.mock";
import { mockWork } from "@js/components/Work/work.gql.mock.js";
import { screen, waitFor } from "@testing-library/react";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import userEvent from "@testing-library/user-event";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

describe("Add fileset to work modal", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(FileSetModal, {
      workId: mockWork.id,
      isHidden: !isModalOpen,
      closeModal: handleClose,
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

  it("renders fileset form", async () => {
    expect(await screen.findByTestId("fileset-form"));
  });
});
