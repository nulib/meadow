import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutIdentifiersMetadata from "./IdentifiersMetadata";
import { IDENTIFIER_METADATA } from "../../../services/metadata";
import { codeListRelatedUrlMock } from "../../Work/controlledVocabulary.gql.mock";

describe("BatchEditAboutIdentifiersMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutIdentifiersMetadata);
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListRelatedUrlMock],
    });
  });

  it("renders the component", async () => {
    expect(
      await screen.findByTestId("identifiers-metadata")
    ).toBeInTheDocument();
  });

  it("renders expected identifiers metadata fields", async () => {
    for (let item of IDENTIFIER_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
    expect(screen.findByTestId("relatedUrl"));
  });
});
