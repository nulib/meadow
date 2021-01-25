import React from "react";
import WorkForm from "./WorkForm";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { createWorkMock } from "@js/components/Work/work.gql.mock";
import userEvent from "@testing-library/user-event";
import { screen } from "@testing-library/react";

describe("ProjectForm component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<WorkForm />, {
      mocks: [createWorkMock],
    });
  });

  it("renders without crashing", () => {
    expect(screen.getAllByTestId("work-form-modal"));
  });

  it("renders form inputs and buttons", () => {
    expect(screen.getByTestId("accession-number-input"));
    expect(screen.getByTestId("title-input"));
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("displays input error when empty form is submitted", async () => {
    userEvent.click(screen.getByTestId("submit-button"));
    expect(await screen.findByTestId("input-errors"));
  });
});
