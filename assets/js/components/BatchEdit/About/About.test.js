import React from "react";
import { screen } from "@testing-library/react";
import BatchEditAbout from "./About";
import {
  withReactHookForm,
  renderWithRouterApollo,
} from "../../../services/testing-helpers";
import { allCodeListMocks } from "../../Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "../../../context/batch-edit-context";
import { CodeListProvider } from "@js/context/code-list-context";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const items = ["ABC123", "ZYC889"];

describe("BatchEditAbout component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAbout, {
      items,
    });

    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <CodeListProvider>
          <Wrapped />
        </CodeListProvider>
      </BatchProvider>,

      {
        mocks: [...allCodeListMocks],
      }
    );
  });

  it("renders Batch Edit About component", async () => {
    expect(await screen.findByTestId("batch-edit-about-tab-wrapper"));
  });

  it("renders core metadata component", async () => {
    expect(await screen.findByTestId("core-metadata"));
  });

  it("renders controlled metadata component", async () => {
    expect(await screen.findByTestId("controlled-metadata"));
  });

  it("renders Identifiers metadata component", async () => {
    expect(await screen.findByTestId("identifiers-metadata"));
  });

  it("renders physical metadata component", async () => {
    expect(await screen.findByTestId("physical-metadata"));
  });

  it("renders rights metadata component", async () => {
    expect(await screen.findByTestId("rights-metadata"));
  });

  it("renders uncontrolled metadata component", async () => {
    expect(await screen.findByTestId("uncontrolled-metadata"));
  });
});
