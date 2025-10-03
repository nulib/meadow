import React from "react";
import { render, screen, act } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom";
import AutoTextArea from "./AutoTextArea";

// --- helpers ---
const LINE_HEIGHT = 20; // px
const PAD_TOP = 4; // px
const PAD_BOTTOM = 4; // px
const PADDING_Y = PAD_TOP + PAD_BOTTOM;

function mockComputedStyle() {
  jest.spyOn(window, "getComputedStyle").mockImplementation(() => {
    return {
      lineHeight: `${LINE_HEIGHT}px`,
      fontSize: "16px",
      paddingTop: `${PAD_TOP}px`,
      paddingBottom: `${PAD_BOTTOM}px`,
      getPropertyValue: () => "",
    };
  });
}

function setScrollHeight(el, px) {
  Object.defineProperty(el, "scrollHeight", {
    configurable: true,
    get: () => px,
  });
}

afterEach(() => {
  jest.restoreAllMocks();
});

describe("AutoTextArea (JS)", () => {
  test("respects initial rows (min) and small padding when single line", () => {
    mockComputedStyle();
    render(<AutoTextArea rows={2} defaultValue="hello" />);
    const ta = screen.getByRole("textbox");

    // Single line of content
    setScrollHeight(ta, LINE_HEIGHT + PADDING_Y);

    // Force a recompute after mount
    act(() => {
      ta.dispatchEvent(new Event("input", { bubbles: true }));
    });

    expect(ta).toHaveAttribute("rows", "2"); // min rows
  });

  test("grows rows when text wraps to multiple lines and sets paddingBottom to 1rem", async () => {
    mockComputedStyle();
    render(<AutoTextArea rows={2} defaultValue="" />);
    const ta = screen.getByRole("textbox");

    // 3 lines of content
    setScrollHeight(ta, 3 * LINE_HEIGHT + PADDING_Y);

    // Typing triggers 'input' events
    await userEvent.type(ta, "line1\nline2\nline3");

    expect(parseInt(ta.getAttribute("rows"), 10)).toBe(3);
  });

  test("shrinks down (but not below min) when content unwraps", async () => {
    mockComputedStyle();
    render(<AutoTextArea rows={2} defaultValue="x" />);
    const ta = screen.getByRole("textbox");

    // Start at 3 lines
    setScrollHeight(ta, 3 * LINE_HEIGHT + PADDING_Y);
    await userEvent.type(ta, "a");
    expect(ta).toHaveAttribute("rows", "3");

    // Unwrap to 1 line
    setScrollHeight(ta, 1 * LINE_HEIGHT + PADDING_Y);
    await userEvent.clear(ta);
    expect(ta).toHaveAttribute("rows", "2"); // min rows
  });

  test("can shrink to 1 row when min rows is 1", async () => {
    mockComputedStyle();
    render(<AutoTextArea rows={1} defaultValue="hello" />);
    const ta = screen.getByRole("textbox");

    // 2 lines
    setScrollHeight(ta, 2 * LINE_HEIGHT + PADDING_Y);
    await userEvent.type(ta, " world");
    expect(ta).toHaveAttribute("rows", "2");

    // Unwrap to 1 line
    setScrollHeight(ta, 1 * LINE_HEIGHT + PADDING_Y);
    await userEvent.clear(ta);
    expect(ta).toHaveAttribute("rows", "1");
  });

  test("caps at 10 rows and sets overflowY to auto when content exceeds 10 lines", async () => {
    mockComputedStyle();
    render(<AutoTextArea rows={2} defaultValue="" />);
    const ta = screen.getByRole("textbox");

    // 15 lines of content
    setScrollHeight(ta, 15 * LINE_HEIGHT + PADDING_Y);
    await userEvent.type(ta, "lots of\nlines\n".repeat(8));
    expect(ta).toHaveAttribute("rows", "10");
  });

  test("recomputes on window resize (wrapping can change)", () => {
    mockComputedStyle();
    render(<AutoTextArea rows={2} defaultValue="abc" />);
    const ta = screen.getByRole("textbox");

    // Before resize: 2 lines
    setScrollHeight(ta, 2 * LINE_HEIGHT + PADDING_Y);
    act(() => {
      ta.dispatchEvent(new Event("input", { bubbles: true }));
    });
    expect(ta).toHaveAttribute("rows", "2");

    // After resize: unwrap to 1 line
    setScrollHeight(ta, 1 * LINE_HEIGHT + PADDING_Y);
    act(() => {
      window.dispatchEvent(new Event("resize"));
    });
    expect(ta).toHaveAttribute("rows", "2"); // min rows is 2
  });

  test("recomputes when controlled value changes from parent", () => {
    mockComputedStyle();
    const { rerender } = render(
      <AutoTextArea rows={2} value={"x"} onChange={() => {}} />,
    );
    const ta = screen.getByRole("textbox");

    // Parent sets multi-line value
    setScrollHeight(ta, 4 * LINE_HEIGHT + PADDING_Y);
    act(() => {
      rerender(
        <AutoTextArea rows={2} value={"x\ny\nz\nw"} onChange={() => {}} />,
      );
      // Ensure effect has a reason to read new scrollHeight in jsdom
      window.dispatchEvent(new Event("resize"));
    });

    expect(ta).toHaveAttribute("rows", "4");
  });
});
