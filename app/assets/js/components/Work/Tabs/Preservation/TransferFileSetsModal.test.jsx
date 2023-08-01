import React from "react";
import TransferFileSetsModal from "./TransferFileSetsModal";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { mockWork } from "@js/components/Work/work.gql.mock.js";
import { screen } from "@testing-library/react";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

describe("Transfer file sets to another work modal", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(TransferFileSetsModal, {
      closeModal: handleClose,
      isVisible: isModalOpen,
      fromWorkId: mockWork.id,
    });
    return renderWithRouterApollo(
      <AuthProvider>
        <Wrapped />
      </AuthProvider>,
      {
        mocks: [
          getCurrentUserMock,
        ],
      }
    );
  });

  it("renders fileset form", async () => {
    expect(await screen.findByTestId("transfer-filesets-form"));
  });
});
