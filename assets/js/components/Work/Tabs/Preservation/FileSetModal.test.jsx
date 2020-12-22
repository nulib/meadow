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
        <Wrapped />
      </AuthProvider>,
      {
        mocks: [getPresignedUrlForFileSetMock, getCurrentUserMock],
      }
    );
  });

  it("renders fileset form", async () => {
    expect(await screen.findByTestId("fileset-form"));
  });

  it("displays input error when the required fields label and description have no value", async () => {
    await waitFor(() => {
      const el = screen.getByTestId("fileset-accession-number-input");
      expect(el);
      userEvent.type(el, "abc124");
      userEvent.click(screen.getByTestId("submit-button"));
    });
    expect(screen.getAllByTestId("input-errors")).toHaveLength(2);
  });
});
