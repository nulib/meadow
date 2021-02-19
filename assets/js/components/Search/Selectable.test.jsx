import React from "react";
import { fireEvent, screen, waitFor } from "@testing-library/react";
import Selectable from "./Selectable";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

const fn = jest.fn();

describe("SearchSelectable component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <Selectable handleSelectItem={fn} />
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock],
      }
    );
  });

  it("renders a checkbox", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("checkbox-search-select"));
    });
  });

  it("calls onChange function handler when selected/deselected", async () => {
    await waitFor(() => {
      screen.getByTestId("checkbox-search-select");
    });
    fireEvent.click(screen.getByTestId("checkbox-search-select"));
    expect(fn).toHaveBeenCalled();
  });
});
