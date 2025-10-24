import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import PlanChatForm from "./Form";

/**
 * Mock AutoTextArea to capture input value and changes
 */
jest.mock("@js/components/Plan/Chat/AutoTextArea", () => ({
  __esModule: true,
  default: (props) => <input data-testid="msg-input" {...props} />,
}));

/**
 * Mock icons used in the form
 */
jest.mock("@js/components/Icon", () => ({
  __esModule: true,
  IconArrowDown: () => <span data-testid="icon-down" />,
  IconList: () => <span data-testid="icon-list" />,
  IconReply: () => <span data-testid="icon-reply" />,
}));

/**
 * Mock recipes module
 */
jest.mock("@js/components/Plan/recipes", () => ({
  __esModule: true,
  recipes: [
    "Add a description to the work based on the visual content of the image",
    "Add, update, or replace subject headings as appropriate",
    "Fill out controlled fields if possible",
  ],
}));

describe("PlanChatForm", () => {
  test("renders input and submit button", () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    expect(screen.getByTestId("msg-input")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /reply/i })).toBeInTheDocument();
  });

  test("renders 'scroll to bottom' button when showScrollButton=true and calls handler", async () => {
    const onScrollToBottom = jest.fn();

    render(
      <PlanChatForm
        showScrollButton={true}
        onScrollToBottom={onScrollToBottom}
        onSubmitMessage={jest.fn()}
      />,
    );

    const scrollBtn = screen.getByRole("button", { name: /scroll to bottom/i });
    expect(scrollBtn).toBeInTheDocument();

    await userEvent.click(scrollBtn);
    expect(onScrollToBottom).toHaveBeenCalledTimes(1);
  });

  test("hides 'scroll to bottom' button when showScrollButton=false", () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    expect(
      screen.queryByRole("button", { name: /scroll to bottom/i }),
    ).not.toBeInTheDocument();
  });

  test("typing updates the input value", async () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    const input = screen.getByTestId("msg-input");
    await userEvent.type(input, "Hello world");
    expect(input).toHaveValue("Hello world");
  });

  test("submit calls onSubmitMessage with trimmed value and clears the input", async () => {
    const onSubmitMessage = jest.fn();

    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={onSubmitMessage}
      />,
    );

    const input = screen.getByTestId("msg-input");
    const submit = screen.getByRole("button", { name: /reply/i });

    await userEvent.type(input, "   Hello world   ");
    await userEvent.click(submit);

    expect(onSubmitMessage).toHaveBeenCalledTimes(1);
    expect(onSubmitMessage).toHaveBeenCalledWith("Hello world");
    expect(input).toHaveValue("");
  });

  test("whitespace-only message does not call onSubmitMessage", async () => {
    const onSubmitMessage = jest.fn();

    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={onSubmitMessage}
      />,
    );

    const input = screen.getByTestId("msg-input");
    const submit = screen.getByRole("button", { name: /reply/i });

    await userEvent.type(input, "     ");
    await userEvent.click(submit);

    expect(onSubmitMessage).not.toHaveBeenCalled();
    expect(input).toHaveValue("     ");
  });

  test("safe when onSubmitMessage is undefined", async () => {
    render(
      <PlanChatForm showScrollButton={false} onScrollToBottom={jest.fn()} />,
    );

    const input = screen.getByTestId("msg-input");
    const submit = screen.getByRole("button", { name: /reply/i });

    await userEvent.type(input, "Hello!");
    await userEvent.click(submit);

    expect(input).toHaveValue("");
  });

  test("forwards placeholder to the input (via mocked AutoTextArea)", () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    expect(screen.getByPlaceholderText(/ask a question/i)).toBeInTheDocument();
  });

  test("form submit event path works (submit the form directly)", async () => {
    const onSubmitMessage = jest.fn();

    const { container } = render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={onSubmitMessage}
      />,
    );

    const input = screen.getByTestId("msg-input");
    const form = container.querySelector("form");

    await userEvent.type(input, "Direct submit");
    fireEvent.submit(form);

    expect(onSubmitMessage).toHaveBeenCalledWith("Direct submit");
    expect(input).toHaveValue("");
  });

  test("renders recipes button", () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    expect(screen.getByRole("button", { name: /recipes/i })).toBeInTheDocument();
  });

  test("clicking recipes button shows recipe dropdown", async () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    const recipesButton = screen.getByRole("button", { name: /recipes/i });

    // Dropdown should not be visible initially
    expect(
      screen.queryByText(
        /Add a description to the work based on the visual content/i,
      ),
    ).not.toBeInTheDocument();

    // Click to show recipes
    await userEvent.click(recipesButton);

    // All three recipes should be visible
    expect(
      screen.getByText(
        /Add a description to the work based on the visual content/i,
      ),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/Add, update, or replace subject headings/i),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/Fill out controlled fields if possible/i),
    ).toBeInTheDocument();
  });

  test("selecting a recipe populates the input and hides dropdown", async () => {
    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={jest.fn()}
      />,
    );

    const recipesButton = screen.getByRole("button", { name: /recipes/i });
    const input = screen.getByTestId("msg-input");

    // Show recipes
    await userEvent.click(recipesButton);

    // Click on second recipe - use fireEvent to avoid triggering document mousedown
    const recipe = screen.getByText(/Add, update, or replace subject headings/i);
    fireEvent.click(recipe);

    // Input should be populated with the recipe text
    expect(input).toHaveValue(
      "Add, update, or replace subject headings as appropriate",
    );

    // Dropdown should be hidden
    expect(
      screen.queryByText(/Add, update, or replace subject headings/i),
    ).not.toBeInTheDocument();
  });

  test("submitting after selecting a recipe clears input and hides dropdown", async () => {
    const onSubmitMessage = jest.fn();

    render(
      <PlanChatForm
        showScrollButton={false}
        onScrollToBottom={jest.fn()}
        onSubmitMessage={onSubmitMessage}
      />,
    );

    const recipesButton = screen.getByRole("button", { name: /recipes/i });
    const input = screen.getByTestId("msg-input");
    const submitButton = screen.getByRole("button", { name: /reply/i });

    // Show recipes and select one - use fireEvent to avoid triggering document mousedown
    await userEvent.click(recipesButton);
    const recipe = screen.getByText(/Fill out controlled fields if possible/i);
    fireEvent.click(recipe);

    // Re-open recipes to test that submit closes it
    await userEvent.click(recipesButton);

    // Submit the form
    await userEvent.click(submitButton);

    // Should have called onSubmitMessage with the recipe text
    expect(onSubmitMessage).toHaveBeenCalledWith(
      "Fill out controlled fields if possible",
    );

    // Input should be cleared
    expect(input).toHaveValue("");

    // Dropdown should be hidden
    expect(
      screen.queryByText(/Fill out controlled fields if possible/i),
    ).not.toBeInTheDocument();
  });
});
