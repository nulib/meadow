import { screen, within } from "@testing-library/react";

import FilesetActionsStatesModal from "@js/components/Work/Tabs/Preservation/FilesetActionStatesModal";
import React from "react";
import { actionStatesMock } from "@js/components/Work/work.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

const defaultProps = {
  closeModal: jest.fn(),
  isVisible: true,
  id: "abc123",
};

describe("FilesetActionsStatesModal", () => {
  it("renders the modal with expected modal title fileset id", async () => {
    renderWithRouterApollo(<FilesetActionsStatesModal {...defaultProps} />, {
      mocks: [actionStatesMock],
    });
    expect(
      await screen.findByTestId("fileset-action-states")
    ).toBeInTheDocument();
    expect(screen.getByTestId("action-states")).toBeInTheDocument();

    expect(
      await screen.findByText("Fileset Action States")
    ).toBeInTheDocument();
    expect(await screen.findByText("Fileset Id: abc123")).toBeInTheDocument();
  });

  it("renders the expected action state rows", async () => {
    renderWithRouterApollo(<FilesetActionsStatesModal {...defaultProps} />, {
      mocks: [actionStatesMock],
    });

    const rows = await screen.findAllByTestId("action-state-row");

    // Action row 1
    within(rows[0]).getByText("Completed Processing FileSet");
    expect(within(rows[0]).getAllByText("Mar 16, 2021 4:22 PM")).toHaveLength(
      2
    );
    within(rows[0]).getByText("OK");

    // Action row 2
    within(rows[1]).getByText("Create pyramid TIFF from source image");
    within(rows[1]).getByText("ERROR");
    within(rows[1]).getByText("I am some notes");
    within(rows[1]).getByText("Mar 16, 2021 4:22 PM");
    within(rows[1]).getByText("Mar 16, 2021 4:23 PM");
  });

  it("does not render the modal when isVisible is false", async () => {
    renderWithRouterApollo(
      <FilesetActionsStatesModal {...defaultProps} isVisible={false} />,
      {
        mocks: [actionStatesMock],
      }
    );
    expect(
      await screen.queryByTestId("fileset-action-states")
    ).not.toBeInTheDocument();
  });

  it("does not render the modal when there is no fileset id", async () => {
    renderWithRouterApollo(
      <FilesetActionsStatesModal {...defaultProps} id={null} />,
      {
        mocks: [actionStatesMock],
      }
    );
    expect(await screen.queryByTestId("action-states")).not.toBeInTheDocument();
  });
});
