import React from "react";
import ReplaceFileSet from "./ReplaceFileSet";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getPresignedUrlForFileSetMock } from "@js/components/IngestSheet/ingestSheet.gql.mock";
import { mockWork } from "@js/components/Work/work.gql.mock.js";
import { screen, fireEvent, waitFor } from "@testing-library/react";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

// Mock the S3ObjectPicker component
jest.mock("@js/components/Work/Tabs/Preservation/S3ObjectPicker", () => {
  return function MockS3ObjectPicker({ onFileSelect }) {
    return (
      <button onClick={() => onFileSelect({ key: "mocked-file.jpg", size: 1000, mimeType: "image/jpeg" })}>
        Select Mocked File
      </button>
    );
  };
});

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

describe("Replace fileset modal", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(ReplaceFileSet, {
      closeModal: handleClose,
      isVisible: isModalOpen,
      fileset: mockWork.fileSets[0],
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


  it("renders replace fileset form", async () => {
    expect(await screen.findByTestId("replace-fileset-form"));
  });

  it("displays warning message", async () => {
    expect(await screen.findByText(/Replacing a fileset cannot be undone/i));
  });

  it("renders file upload dropzone", async () => {
    expect(await screen.findByText(/Drag 'n' drop a file here, or click to select file/i));
  });

  it("renders label input field", async () => {
    expect(await screen.findByTestId("fileset-label-input"));
  });

  it("renders description input field", async () => {
    expect(await screen.findByTestId("fileset-description-input"));
  });

  it("renders cancel and submit buttons when file is selected from S3ObjectPicker", async () => {
    const selectFileButton = await screen.findByText("Select Mocked File");
    fireEvent.click(selectFileButton);

    await waitFor(() => {
      expect(screen.getByTestId("cancel-button")).toBeInTheDocument();
      expect(screen.getByTestId("submit-button")).toBeInTheDocument();
    });
  });
});