import React from "react";
import BatchEditTabs from "./Tabs";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";

const items = ["ABC123", "ZYC889"];

describe("BatchEditTabs component", () => {
  function setupTest() {
    return renderWithRouterApollo(<BatchEditTabs items={items} />);
  }

  it("renders the tabs header", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-tabs")).toBeInTheDocument();
      expect(getByTestId("tab-about")).toBeInTheDocument();
      expect(getByTestId("tab-administrative")).toBeInTheDocument();
    });
  });

  it("renders the about tab and content", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("tab-about")).toBeInTheDocument();
      expect(getByTestId("tab-about-content")).toBeInTheDocument();
    });
  });

  it("renders the administrative tab and content", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("tab-administrative")).toBeInTheDocument();
      expect(getByTestId("tab-administrative-content")).toBeInTheDocument();
    });
  });
});
