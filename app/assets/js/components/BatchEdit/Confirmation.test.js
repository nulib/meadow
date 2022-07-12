import React from "react";
import { screen } from "@testing-library/react";
import BatchEditConfirmation from "@js/components/BatchEdit/Confirmation";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import userEvent from "@testing-library/user-event";

const props = {
  batchAdds: {
    administrativeMetadata: {
      projectName: ["Ima Project"],
      projectManager: ["Bob Marley"],
    },
    descriptiveMetadata: {
      contributor: [
        {
          term: "http://id.worldcat.org/fast/1411628",
          role: { id: "art", scheme: "MARC_RELATOR" },
          label: "History",
        },
      ],
      genre: [
        { term: "http://id.worldcat.org/fast/1204623", label: "Great Britain" },
      ],
      description: ["New description"],
      caption: ["caption 1", "caption 2"],
      keywords: ["some, keywords, here", "ima keyword"],
    },
  },
  batchDeletes: {
    genre: [
      {
        term: "http://vocab.getty.edu/aat/300128343",
        label: "black-and-white negatives",
      },
    ],
    stylePeriod: [
      {
        term: "http://vocab.getty.edu/aat/300128343",
        label: "black-and-white negatives",
      },
    ],
    subject: [
      {
        term: "http://id.loc.gov/authorities/names/n86066573",
        label: "Hinton, Sam, 1917-2009 (Topical)",
        role: { id: "TOPICAL", scheme: "SUBJECT_ROLE" },
      },
      {
        term: "http://id.loc.gov/authorities/names/n79118971",
        label: "Oakland (Calif.) (Geographical)",
        role: { id: "GEOGRAPHICAL", scheme: "SUBJECT_ROLE" },
      },
    ],
  },
  batchReplaces: {
    administrativeMetadata: {
      preservationLevel: {
        id: "2",
        scheme: "PRESERVATION_LEVEL",
        label: "Level 2",
      },
      libraryUnit: {
        id: "FACULTY_COLLECTIONS",
        scheme: "LIBRARY_UNIT",
        label: "Faculty Collections",
      },
      status: { id: "IN PROGRESS", scheme: "STATUS", label: "In Progress" },
    },
    published: { publish: true, unpublish: false },
    descriptiveMetadata: {
      relatedUrl: [
        {
          url: "https://www.northwestern.edu/testing",
          label: { scheme: "RELATED_URL", id: "HATHI_TRUST_DIGITAL_LIBRARY" },
        },
        {
          url: "http://urgeoverkill.com",
          label: { scheme: "RELATED_URL", id: "FINDING_AID" },
        },
      ],
      rightsStatement: {
        id: "http://rightsstatements.org/vocab/InC/1.0/",
        scheme: "RIGHTS_STATEMENT",
        label: "In Copyright",
      },
      title: "Some title",
      alternateTitle: ["Alt title here"],
      dateCreated: [],
    },
  },
  batchVisibility: { id: "OPEN", scheme: "VISIBILITY", label: "Public" },
  batchCollection: {
    id: "c7f1196d-fcb0-4398-86c0-fa836dbd2880",
    title: "Department of Art History || Architecture Collection",
  },
  filteredQuery:
    '{"query":{"bool":{"must":[{"bool":{"must":[{"bool":{"should":[{"terms":{"descriptiveMetadata.contributor.displayFacet":["Olivier, Barry, 1935- (Photographer)"]}}]}},{"bool":{"must":[{"match":{"model.name":"Work"}}]}}]}}]}}}',
  handleClose: jest.fn(),
  handleFormReset: jest.fn(),
  isConfirmModalOpen: true,
  numberOfResults: 4,
};

describe("BatchEditConfirmation component test", () => {
  function renderComponent(restProps) {
    const allProps = { ...props, ...restProps };

    return renderWithRouterApollo(
      <CodeListProvider>
        <BatchEditConfirmation {...allProps} />
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
    );
  }

  it("renders the confirmation modal", async () => {
    const { findByTestId, debug } = renderComponent();
    expect(await findByTestId("modal-batch-edit-confirmation"));
  });

  it("renders add section", () => {
    renderComponent();
    expect(screen.getByTestId("confirmation-adds"));
  });

  it("does not render add section when no add items are passed in", () => {
    renderComponent({
      batchAdds: { administrativeMetadata: {}, descriptiveMetadata: {} },
    });
    expect(screen.queryByTestId("confirmation-adds")).toBeFalsy();
  });

  it("renders deletes section", () => {
    renderComponent();
    expect(screen.getByTestId("confirmation-deletes"));
  });

  it("does not render deletes section when no delete items passed in", () => {
    renderComponent({
      batchDeletes: {},
    });
    expect(screen.queryByTestId("confirmation-deletes")).toBeFalsy();
  });

  it("renders replaces section", () => {
    renderComponent();
    expect(screen.getByTestId("confirmation-replaces"));
  });

  it("renders replaces section for a Collection only update", () => {
    renderComponent({
      batchReplaces: {
        administrativeMetadata: {},
        descriptiveMetadata: {},
        published: false,
      },
      batchVisibility: {},
    });
    expect(screen.getByTestId("confirmation-replaces"));
  });

  it("renders replaces section for a Visibility only update", () => {
    renderComponent({
      batchReplaces: {
        administrativeMetadata: {},
        descriptiveMetadata: {},
        published: false,
      },
      batchCollection: {},
    });
    expect(screen.getByTestId("confirmation-replaces"));
  });

  it("does not render the replaces section when no replaces items sent in", () => {
    renderComponent({
      batchReplaces: {
        administrativeMetadata: {},
        descriptiveMetadata: {},
        published: false,
      },
      batchCollection: {},
      batchVisibility: {},
    });
    expect(screen.queryByTestId("confirmation-replaces")).toBeFalsy();
  });

  it("renders the confirmation text field", () => {
    renderComponent();
    expect(screen.getByTestId("input-confirmation-text"));
  });

  it("renders the nickname text input and submit button when valid data exists", () => {
    renderComponent();
    expect(screen.getByTestId("input-batch-nickname"));
    expect(screen.getByTestId("button-submit"));
  });

  describe("Submit button", () => {
    it("is enabled after typing confirmation text, and calls its callback function", async () => {
      const user = userEvent.setup();

      renderComponent();

      let button = screen.getByTestId("button-submit");
      let textInput = screen.getByTestId("input-confirmation-text");
      expect(button).toBeDisabled();

      await user.type(textInput, "I refuse to understand");
      expect(button).toBeDisabled();

      await user.clear(textInput);

      await user.type(textInput, "I understand");
      expect(button).toBeEnabled();
    });
  });
});
