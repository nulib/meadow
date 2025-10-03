// AutoResizeTextarea.test.jsx
import React from "react";
import { render, screen, act } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom";
import AutoResizeTextarea from "@/js/components/Plan/Chat/AutoResizeTextarea";

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

describe("AutoResizeTextarea (JS)", () => {
  test("respects initial rows (min) and small padding when single line", () => {
    mockComputedStyle();
    render(<AutoResizeTextarea rows={2} defaultValue="hello" />);
    const ta = screen.getByRole("textbox");

    // Single line of content
    setScrollHeight(ta, LINE_HEIGHT + PADDING_Y);

    // Force a recompute after mount
    act(() => {
      ta.dispatchEvent(new Event("input", { bubbles: true }));
    });

    expect(ta).toHaveAttribute("rows", "2"); // min rows
    expect(ta).toHaveStyle({ paddingBottom: "0.4rem", overflowY: "hidden" });
  });

  test("grows rows when text wraps to multiple lines and sets paddingBottom to 1rem", async () => {
    mockComputedStyle();
    render(<AutoResizeTextarea rows={2} defaultValue="" />);
    const ta = screen.getByRole("textbox");

    // 3 lines of content
    setScrollHeight(ta, 3 * LINE_HEIGHT + PADDING_Y);

    // Typing triggers 'input' events
    await userEvent.type(ta, "line1\nline2\nline3");

    expect(parseInt(ta.getAttribute("rows"), 10)).toBe(3);
    expect(ta).toHaveStyle({ paddingBottom: "1rem", overflowY: "hidden" });
  });

  test("shrinks down (but not below min) when content unwraps", async () => {
    mockComputedStyle();
    render(<AutoResizeTextarea rows={2} defaultValue="x" />);
    const ta = screen.getByRole("textbox");

    // Start at 3 lines
    setScrollHeight(ta, 3 * LINE_HEIGHT + PADDING_Y);
    await userEvent.type(ta, "a");
    expect(ta).toHaveAttribute("rows", "3");

    // Unwrap to 1 line
    setScrollHeight(ta, 1 * LINE_HEIGHT + PADDING_Y);
    await userEvent.clear(ta);
    expect(ta).toHaveAttribute("rows", "2"); // min rows
    expect(ta).toHaveStyle({ paddingBottom: "0.4rem" });
  });

  test("can shrink to 1 row when min rows is 1", async () => {
    mockComputedStyle();
    render(<AutoResizeTextarea rows={1} defaultValue="hello" />);
    const ta = screen.getByRole("textbox");

    // 2 lines
    setScrollHeight(ta, 2 * LINE_HEIGHT + PADDING_Y);
    await userEvent.type(ta, " world");
    expect(ta).toHaveAttribute("rows", "2");

    // Unwrap to 1 line
    setScrollHeight(ta, 1 * LINE_HEIGHT + PADDING_Y);
    await userEvent.clear(ta);
    expect(ta).toHaveAttribute("rows", "1");
    expect(ta).toHaveStyle({ paddingBottom: "0.4rem" });
  });

  test("caps at 10 rows and sets overflowY to auto when content exceeds 10 lines", async () => {
    mockComputedStyle();
    render(<AutoResizeTextarea rows={2} defaultValue="" />);
    const ta = screen.getByRole("textbox");

    // 15 lines of content
    setScrollHeight(ta, 15 * LINE_HEIGHT + PADDING_Y);
    await userEvent.type(ta, "lots of\nlines\n".repeat(8));
    expect(ta).toHaveAttribute("rows", "10");
    expect(ta).toHaveStyle({ overflowY: "auto", paddingBottom: "1rem" });
  });

  test("recomputes on window resize (wrapping can change)", () => {
    mockComputedStyle();
    render(<AutoResizeTextarea rows={2} defaultValue="abc" />);
    const ta = screen.getByRole("textbox");

    // Before resize: 2 lines
    setScrollHeight(ta, 2 * LINE_HEIGHT + PADDING_Y);
    act(() => {
      ta.dispatchEvent(new Event("input", { bubbles: true }));
    });
    expect(ta).toHaveAttribute("rows", "2");
    expect(ta).toHaveStyle({ paddingBottom: "1rem" });

    // After resize: unwrap to 1 line
    setScrollHeight(ta, 1 * LINE_HEIGHT + PADDING_Y);
    act(() => {
      window.dispatchEvent(new Event("resize"));
    });
    expect(ta).toHaveAttribute("rows", "2"); // min rows is 2
    expect(ta).toHaveStyle({ paddingBottom: "0.4rem" });
  });

  test("recomputes when controlled value changes from parent", () => {
    mockComputedStyle();
    const { rerender } = render(
      <AutoResizeTextarea rows={2} value={"x"} onChange={() => {}} />,
    );
    const ta = screen.getByRole("textbox");

    // Parent sets multi-line value
    setScrollHeight(ta, 4 * LINE_HEIGHT + PADDING_Y);
    act(() => {
      rerender(
        <AutoResizeTextarea
          rows={2}
          value={"x\ny\nz\nw"}
          onChange={() => {}}
        />,
      );
      // Ensure effect has a reason to read new scrollHeight in jsdom
      window.dispatchEvent(new Event("resize"));
    });

    expect(ta).toHaveAttribute("rows", "4");
    expect(ta).toHaveStyle({ paddingBottom: "1rem" });
  });
});
