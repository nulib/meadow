import React from "react";
import Work from "./Work";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import {
  mockWork,
  workArchiverEndpointMock,
  dcApiTokenMock,
} from "./work.gql.mock";
import { dcApiEndpointMock } from "@js/components/UI/ui.gql.mock";
import { iiifServerUrlMock } from "@js/components/IIIF/iiif.gql.mock";
import { screen } from "@testing-library/react";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import {
  getCollectionMock,
  getCollectionsMock,
} from "@js/components/Collection/collection.gql.mock";
import { WorkProvider } from "@js/context/work-context";

jest.mock("@js/services/get-api-response-headers");

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [
  dcApiTokenMock,
  dcApiEndpointMock,
  iiifServerUrlMock,
  getCollectionMock,
  getCollectionsMock,
  workArchiverEndpointMock,
  ...allCodeListMocks,
];

jest.mock("@samvera/clover-iiif/viewer", () => {
  return {
    __esModule: true,
    default: (props) => {
      // Call the canvasCallback with a string when the component is rendered
      if (props.canvasCallback) {
        props.canvasCallback(
          "https://mat.dev.rdc.library.northwestern.edu:3002/works/a1239c42-6e26-4a95-8cde-0fa4dbf0af6a?as=iiif/canvas/access/0",
        );
      }
      return <div></div>;
    },
  };
});

describe("Work component", () => {
  beforeEach(() => {
    renderWithRouterApollo(
      <WorkProvider>
        <Work work={mockWork} />
      </WorkProvider>,
      { mocks },
    );
  });

  it("renders without crashing", async () => {
    expect(await screen.findByTestId("work-component"));
  });

  //TODO: Figure out how to accurately test this component in relative isolation
  // and not have to mock every child dependency the whole component tree needs
  xit("renders the viewer and tabs", async () => {
    expect(await screen.findByTestId("viewer"));
    expect(await screen.findByTestId("tabs-wrapper"));
  });
});
