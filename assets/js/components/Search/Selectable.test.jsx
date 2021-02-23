import React from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import Selectable from "./Selectable";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const fn = jest.fn();

describe("SearchSelectable component", () => {
  beforeEach(() => {
    return render(<Selectable handleSelectItem={fn} />);
  });

  it("renders a checkbox", async () => {
    expect(await screen.findByTestId("checkbox-search-select"));
  });

  it("calls onChange function handler when selected/deselected", async () => {
    await waitFor(() => {
      screen.getByTestId("checkbox-search-select");
    });
    fireEvent.click(screen.getByTestId("checkbox-search-select"));
    expect(fn).toHaveBeenCalled();
  });
});
