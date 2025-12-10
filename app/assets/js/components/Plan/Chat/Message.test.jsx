import React from "react";
import { render, screen } from "@testing-library/react";
import PlanChatMessage from "./Message";

describe("PlanChatMessage", () => {
  test("renders the message content", () => {
    render(<PlanChatMessage content="Hello!" isUser={true} />);
    const article = screen.getByText("Hello!");
    expect(article).toBeInTheDocument();
    expect(article).toHaveClass("chat-message");
  });

  test("sets data attributes correctly for a user message", () => {
    render(<PlanChatMessage content="Hi" isUser={true} type="message" />);
    const article = screen.getByText("Hi");
    expect(article).toHaveAttribute("data-message-user", "human");
    expect(article).toHaveAttribute("data-message-type", "message");
  });

  test("sets data attributes correctly for an AI message", () => {
    render(
      <PlanChatMessage content="Hello from AI" isUser={false} type="message" />,
    );
    const article = screen.getByText("Hello from AI");
    expect(article).toHaveAttribute("data-message-user", "ai");
    expect(article).toHaveAttribute("data-message-type", "message");
  });

  test("renders with default type='message' when not provided", () => {
    render(<PlanChatMessage content="Default type" isUser={false} />);
    const article = screen.getByText("Default type");
    expect(article).toHaveAttribute("data-message-type", "message");
  });

  test("renders with type='error' when provided", () => {
    render(
      <PlanChatMessage
        content="Something went wrong"
        isUser={false}
        type="error"
      />,
    );
    const article = screen.getByText("Something went wrong");
    expect(article).toHaveAttribute("data-message-type", "error");
  });

  test("supports React node content", () => {
    render(
      <PlanChatMessage
        content={<span data-testid="child">nested</span>}
        isUser={true}
        type="message"
      />,
    );
    const child = screen.getByTestId("child");
    expect(child).toBeInTheDocument();
    const article = child.closest("article");
    expect(article).toHaveAttribute("data-message-user", "human");
    expect(article).toHaveAttribute("data-message-type", "message");
  });

  test("updates correctly when props change", () => {
    const { rerender } = render(
      <PlanChatMessage content="first" isUser={true} type="message" />,
    );

    let article = screen.getByText("first");
    expect(article).toHaveAttribute("data-message-user", "human");
    expect(article).toHaveAttribute("data-message-type", "message");

    rerender(
      <PlanChatMessage content="error occurred" isUser={false} type="error" />,
    );
    article = screen.getByText("error occurred");
    expect(article).toHaveAttribute("data-message-user", "ai");
    expect(article).toHaveAttribute("data-message-type", "error");
  });
});
