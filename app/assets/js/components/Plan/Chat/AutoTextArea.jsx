import React, { useRef, useEffect, useCallback } from "react";

export default function AutoResizeTextarea({ rows = 2, ...props }) {
  const textareaRef = useRef(null);

  const resize = useCallback(() => {
    const el = textareaRef.current;
    if (!el) return;

    const cs = window.getComputedStyle(el);
    const lineHeight =
      parseFloat(cs.lineHeight) || parseFloat(cs.fontSize) * 1.2 || 20;
    const paddingY =
      (parseFloat(cs.paddingTop) || 0) + (parseFloat(cs.paddingBottom) || 0);

    // Measure content lines independent of current rows by temporarily setting to 1
    const prevRows = el.rows;
    el.rows = 1;
    const contentLines = Math.max(
      1,
      Math.ceil((el.scrollHeight - paddingY) / lineHeight),
    );

    // Determine target rows with min = `rows` and max = 10
    const targetRows = Math.min(10, Math.max(rows, contentLines));
    el.rows = targetRows;

    // Padding toggles when text wraps onto a second line (contentLines > 1)
    el.style.paddingBottom = contentLines > 1 ? "1rem" : "0.4rem";

    // Only show vertical scroll if content exceeds max rows
    el.style.overflowY =
      targetRows >= 10 && contentLines > 10 ? "auto" : "hidden";
  }, [rows]);

  useEffect(() => {
    resize();
    const el = textareaRef.current;
    if (!el) return;
    el.addEventListener("input", resize);
    window.addEventListener("resize", resize);
    return () => {
      el.removeEventListener("input", resize);
      window.removeEventListener("resize", resize);
    };
  }, [resize]);

  // Recalculate when controlled `value` changes from the parent
  useEffect(() => {
    resize();
  }, [props.value, resize]);

  return (
    <textarea className="textarea" {...props} rows={rows} ref={textareaRef} />
  );
}
