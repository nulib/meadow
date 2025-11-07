import { render, screen, waitFor } from "@testing-library/react";
import {
  renderWithReactHookForm,
  withReactBeautifulDND,
} from "@js/services/testing-helpers";

import React from "react";
import WorkFilesetList from "./ListItem";
import { WorkProvider } from "@js/context/work-context";
import { mockFileSets } from "@js/mock-data/filesets";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

// Mock child components
jest.mock("@js/components/Work/Fileset/ActionButtons/Access", () => {
  return {
    __esModule: true,
    default: () => {
      return <div>Mocked Access</div>;
    },
  };
});
jest.mock("@js/components/Work/Fileset/ActionButtons/Auxillary", () => {
  return {
    __esModule: true,
    default: () => {
      return <div>Mocked Auxillary</div>;
    },
  };
});

describe("Fileset component", () => {
  describe("when not editing", () => {
    function setUpTests(workImageFilesetId) {
      return render(
        <WorkProvider>
          <WorkFilesetList
            fileSet={mockFileSets[0]}
            workImageFilesetId={workImageFilesetId}
          />
        </WorkProvider>,
      );
    }
    it("renders the image preview, label, description, alt text, and image caption", async () => {
      setUpTests();
      await waitFor(() => {
        expect(screen.getByTestId("fileset-item"));
        expect(screen.getByTestId("fileset-image"));
        expect(screen.getByText(mockFileSets[0].coreMetadata.label));
        expect(screen.getByText(mockFileSets[0].coreMetadata.description));
        expect(screen.getByText(mockFileSets[0].coreMetadata.altText));
        expect(screen.getByText(mockFileSets[0].coreMetadata.imageCaption));
      });
    });

    describe("Image and Video work types", () => {
      it("renders an checked Work image toggle if current fileset is a representative Work image", async () => {
        setUpTests(mockFileSets[0].id);
        await waitFor(() => {
          const toggleEl = screen.getByTestId("work-image-selector");
          expect(toggleEl).toBeChecked();
        });
      });

      it("renders an unchecked Work image toggle if current fileset is NOT a representative Work image", async () => {
        setUpTests("ABC123");
        await waitFor(() => {
          const toggleEl = screen.getByTestId("work-image-selector");
          expect(toggleEl).not.toBeChecked();
        });
      });

      it("renders the Work image toggle if the fileset is a video and has a representative image", async () => {
        render(
          <WorkProvider>
            <WorkFilesetList
              fileSet={mockFileSets[3]}
              workImageFilesetId={mockFileSets[3].id}
            />
          </WorkProvider>,
        );

        const toggleEl = await screen.findByTestId("work-image-selector");
        expect(toggleEl).toBeInTheDocument();
      });

      it("does not render the image toggle if the fileset is a video and does not have a representative image", async () => {
        const fileSet = {
          ...mockFileSets[3],
          representativeImageUrl: null,
        };

        render(
          <WorkProvider>
            <WorkFilesetList
              fileSet={fileSet}
              workImageFilesetId={mockFileSets[3].id}
            />
          </WorkProvider>,
        );

        const toggleEl = screen.queryByTestId("work-image-selector");
        expect(toggleEl).not.toBeInTheDocument();
      });
    });

    describe("Audio work type", () => {
      // Set up the test so the Work type id is "AUDIO"
      const initialState = {
        activeMediaFileSet: null,
        webVttModal: {
          fileSetId: null,
          isOpen: false,
          webVttString: "",
        },
        workTypeId: "AUDIO",
      };
      it("doesn't render the Work image toggle", () => {
        render(
          <WorkProvider initialState={initialState}>
            <WorkFilesetList
              fileSet={mockFileSets[0]}
              workImageFilesetId={undefined}
            />
          </WorkProvider>,
        );
        expect(
          screen.queryByTestId("work-image-selector"),
        ).not.toBeInTheDocument();
      });
    });
  });

  describe("when editing", () => {
    beforeEach(() => {
      const Wrapped = withReactBeautifulDND(WorkFilesetList, {
        fileSet: mockFileSets[0],
        index: 0,
        isEditing: true,
      });

      return renderWithReactHookForm(<WorkProvider>{Wrapped}</WorkProvider>);
    });

    it("renders the component", async () => {
      expect(await screen.findByTestId("fileset-item"));
    });

    it("renders label, description, alt text, and image caption form elements", () => {
      expect(screen.getByTestId("fileset-image"));
      expect(screen.getByTestId("input-label"));
      expect(screen.getByTestId("textarea-metadata-description"));
      expect(screen.getByTestId("input-alt-text"));
      expect(screen.getByTestId("textarea-metadata-image-caption"));
    });

    it("does not render the toggle representative Work checkbox", () => {
      expect(screen.queryByTestId("work-image-selector")).toBeNull();
    });
  });
});
