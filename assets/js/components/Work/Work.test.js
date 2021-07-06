import React from "react";
import Work from "./Work";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { mockWork } from "./work.gql.mock";
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

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [
  iiifServerUrlMock,
  getCollectionMock,
  getCollectionsMock,
  ...allCodeListMocks,
];

jest.mock("@js/services/get-manifest");

describe("Work component", () => {
  beforeEach(() => {
    renderWithRouterApollo(
      <WorkProvider>
        <Work work={mockWork} />
      </WorkProvider>,
      { mocks }
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
