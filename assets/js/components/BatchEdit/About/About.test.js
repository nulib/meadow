import React from "react";
import { waitFor, screen } from "@testing-library/react";
import BatchEditAbout from "./About";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { allCodeListMocks } from "../../Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "../../../context/batch-edit-context";
import { CodeListProvider } from "@js/context/code-list-context";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

const items = ["ABC123", "ZYC889"];

describe("BatchEditAbout component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <BatchProvider value={null}>
          <CodeListProvider>
            <BatchEditAbout items={items} />
          </CodeListProvider>
        </BatchProvider>
      </AuthProvider>,
      {
        mocks: [...allCodeListMocks, getCurrentUserMock],
      }
    );
  });

  it("renders Batch Edit About form", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("batch-edit-about-form"));
    });
  });

  it("renders the sticky header", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("batch-edit-about-sticky-header"));
    });
  });

  it("renders core metadata component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("core-metadata"));
    });
  });

  it("renders controlled metadata component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("controlled-metadata"));
    });
  });

  it("renders Identifiers metadata component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("identifiers-metadata"));
    });
  });

  it("renders physical metadata component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("physical-metadata"));
    });
  });

  it("renders rights metadata component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("rights-metadata"));
    });
  });

  it("renders uncontrolled metadata component", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("uncontrolled-metadata"));
    });
  });
});
