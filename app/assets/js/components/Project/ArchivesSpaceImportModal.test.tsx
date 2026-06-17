import React from "react";
import { fireEvent, screen, waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { AuthContext } from "@js/components/Auth/Auth";
import ProjectArchivesSpaceImportModal from "./ArchivesSpaceImportModal";
import {
  archivesSpaceImportPreviewSubscriptionMock,
  importArchivesSpaceResourceMock,
  importArchivesSpaceResourceAiMock,
  searchArchivesSpaceResourcesBlockedMock,
  searchArchivesSpaceResourcesEmptyMock,
  searchArchivesSpaceResourcesMock,
  startArchivesSpaceImportPreviewMock,
  MOCK_RESOURCE_TITLE,
} from "./archivesSpace.gql.mock";

const mocks = [
  searchArchivesSpaceResourcesMock,
  searchArchivesSpaceResourcesBlockedMock,
  searchArchivesSpaceResourcesEmptyMock,
  importArchivesSpaceResourceMock,
  importArchivesSpaceResourceAiMock,
  startArchivesSpaceImportPreviewMock,
  archivesSpaceImportPreviewSubscriptionMock,
];

type TestUser = {
  role: string;
};

type RenderModalOptions = {
  closeModal?: () => void;
  user?: TestUser;
};

function renderModal({
  closeModal = jest.fn(),
  user,
}: RenderModalOptions = {}) {
  renderWithRouterApollo(
    <AuthContext.Provider value={user}>
      <ProjectArchivesSpaceImportModal
        closeModal={closeModal}
        isHidden={false}
      />
    </AuthContext.Provider>,
    { mocks },
  );
}

describe("ProjectArchivesSpaceImportModal", () => {
  let closeModal: jest.Mock;

  beforeEach(() => {
    closeModal = jest.fn();
  });

  function search(term: string) {
    fireEvent.change(
      screen.getByLabelText("Search ArchivesSpace collections"),
      { target: { value: term } },
    );
    fireEvent.submit(screen.getByTestId("archivesspace-search-form"));
  }

  it("renders the modal with a disabled import button", () => {
    renderModal({ closeModal });
    expect(
      screen.getByTestId("archivesspace-import-modal"),
    ).toBeInTheDocument();
    expect(screen.getByTestId("button-import-resource")).toBeDisabled();
  });

  it("searches ArchivesSpace and displays results", async () => {
    renderModal({ closeModal });
    search("folk");

    expect(await screen.findByText(MOCK_RESOURCE_TITLE)).toBeInTheDocument();
    expect(screen.getByText("Folk Dance Society Records")).toBeInTheDocument();
    expect(screen.getByText("MS-63")).toBeInTheDocument();
  });

  it("displays a message when nothing matches", async () => {
    renderModal({ closeModal });
    search("nothing");

    expect(
      await screen.findByTestId("archivesspace-no-results"),
    ).toBeInTheDocument();
  });

  it("imports the selected resource and closes the modal", async () => {
    renderModal({ closeModal });
    search("folk");
    await screen.findByText(MOCK_RESOURCE_TITLE);

    fireEvent.click(screen.getByLabelText(`Select ${MOCK_RESOURCE_TITLE}`));

    const importButton = screen.getByTestId("button-import-resource");
    expect(importButton).not.toBeDisabled();
    fireEvent.click(importButton);

    await waitFor(() => expect(closeModal).toHaveBeenCalled());
  });

  it("shows blocked resources but does not allow import", async () => {
    renderModal({ closeModal });
    search("blocked");

    expect(
      await screen.findByText("Already in Digital Collections"),
    ).toBeInTheDocument();
    expect(screen.getByTestId("archivesspace-blocked-tag")).toBeInTheDocument();
    expect(
      screen.getByTestId("archivesspace-import-blocked"),
    ).toBeInTheDocument();
    expect(
      screen.getByLabelText("Select Already in Digital Collections"),
    ).toBeDisabled();
    expect(screen.getByTestId("button-import-resource")).toBeDisabled();
  });

  it("hides the AI metadata checkbox for users without an AI ingest role", () => {
    renderModal({ closeModal, user: { role: "MANAGER" } });
    expect(
      screen.queryByText("Enable AI-generated metadata"),
    ).not.toBeInTheDocument();
  });

  it("previews, requires acknowledgment, then imports with AI ingest enabled", async () => {
    renderModal({ closeModal, user: { role: "ADMINISTRATOR" } });
    search("folk");
    await screen.findByText(MOCK_RESOURCE_TITLE);

    fireEvent.click(screen.getByLabelText(`Select ${MOCK_RESOURCE_TITLE}`));
    fireEvent.click(screen.getByRole("checkbox"));

    // With AI ingest enabled the primary button generates a preview first.
    const button = screen.getByTestId("button-import-resource");
    expect(button).toHaveTextContent("Generate preview");
    fireEvent.click(button);

    // The preview renders the sampled works and an estimated cost.
    expect(
      await screen.findByTestId("archivesspace-preview"),
    ).toBeInTheDocument();
    expect(screen.getByText("Poster 1, 1968")).toBeInTheDocument();
    expect(screen.getByText(/\$4\.20/)).toBeInTheDocument();

    // Import stays blocked until the reviewer acknowledges.
    expect(screen.getByTestId("button-import-resource")).toBeDisabled();
    fireEvent.click(screen.getByTestId("archivesspace-preview-understood"));

    const importButton = screen.getByTestId("button-import-resource");
    expect(importButton).toHaveTextContent("Import collection");
    expect(importButton).not.toBeDisabled();
    fireEvent.click(importButton);

    // The aiIngest: true mock resolves only if the mutation sent aiIngest: true
    await waitFor(() => expect(closeModal).toHaveBeenCalled());
  });
});
