jest.mock("@js/components/Plan/fields", () => {
  const WORK_FIELDS = {
    accessionNumber: "Accession Number",
    descriptive_metadata: {
      title: "Title",
      description: "Description",
      subject: "Subject",
      creator: "Creator",
    },
    visibility: "Visibility",
  };

  const CONTROLLED_TERM_FIELDS = new Set([
    "descriptive_metadata.subject",
    "descriptive_metadata.creator",
  ]);

  return { WORK_FIELDS, CONTROLLED_TERM_FIELDS };
});

import { toArray, isControlled, getFieldLabel, toRows } from "./diff-helpers";

describe("diff-helpers", () => {
  describe("toArray", () => {
    test("returns the same array when already an array", () => {
      const arr = [1, 2];
      expect(toArray(arr)).toBe(arr);
    });

    test("wraps truthy non-array values", () => {
      expect(toArray("x")).toEqual(["x"]);
      expect(toArray(42)).toEqual([42]);
      expect(toArray({ a: 1 })).toEqual([{ a: 1 }]);
    });

    test("returns [] for null or undefined", () => {
      expect(toArray(null)).toEqual([]);
      expect(toArray(undefined)).toEqual([]);
    });
  });

  describe("isControlled", () => {
    test("returns true for controlled paths", () => {
      expect(isControlled("descriptive_metadata.subject")).toBe(true);
      expect(isControlled("descriptive_metadata.creator")).toBe(true);
    });

    test("returns false for non-controlled paths", () => {
      expect(isControlled("descriptive_metadata.title")).toBe(false);
      expect(isControlled("visibility")).toBe(false);
    });
  });

  describe("getFieldLabel", () => {
    const LOCAL_FIELDS = {
      descriptive_metadata: {
        title: "Title",
        description: "Description",
        subject: "Subject",
        creator: "Creator",
      },
      visibility: "Visibility",
    };

    test("resolves labels from WORK_FIELDS", () => {
      expect(getFieldLabel("descriptive_metadata.title", LOCAL_FIELDS)).toBe(
        "Title",
      );
      expect(getFieldLabel("descriptive_metadata.subject", LOCAL_FIELDS)).toBe(
        "Subject",
      );
      expect(getFieldLabel("visibility", LOCAL_FIELDS)).toBe("Visibility");
    });

    test("falls back to last segment for unknown paths", () => {
      expect(
        getFieldLabel("descriptive_metadata.unknown_field", LOCAL_FIELDS),
      ).toBe("unknown_field");
      expect(getFieldLabel("nonexistent.root", LOCAL_FIELDS)).toBe("root");
    });
  });

  describe("toRows", () => {
    test("emits a controlled row and does not descend into controlled paths", () => {
      const change = {
        descriptive_metadata: {
          subject: [
            { term: { id: "t1", label: "Term 1" } },
            { term: { id: "t2", label: "Term 2" } },
          ],
        },
      };

      const rows = toRows(change, "add");
      expect(rows).toHaveLength(1);

      const row = rows[0];
      expect(row).toMatchObject({
        id: "add-descriptive_metadata.subject",
        method: "add",
        path: "descriptive_metadata.subject",
        label: "Subject",
        controlled: true,
      });
      expect(row.value).toEqual(change.descriptive_metadata.subject);
    });

    test("emits rows for primitives and arrays (controlled=false) and uses field labels", () => {
      const change = {
        descriptive_metadata: {
          title: "St. Denis",
          description: ["Line 1", "Line 2"],
        },
        visibility: "Public",
      };

      const rows = toRows(change, "replace");
      expect(rows.map((r) => r.path).sort()).toEqual(
        [
          "descriptive_metadata.title",
          "descriptive_metadata.description",
          "visibility",
        ].sort(),
      );

      const titleRow = rows.find(
        (r) => r.path === "descriptive_metadata.title",
      );
      expect(titleRow).toMatchObject({
        method: "replace",
        label: "Title",
        controlled: false,
        value: "St. Denis",
      });

      const descRow = rows.find(
        (r) => r.path === "descriptive_metadata.description",
      );
      expect(descRow).toMatchObject({
        method: "replace",
        label: "Description",
        controlled: false,
        value: ["Line 1", "Line 2"],
      });

      const visRow = rows.find((r) => r.path === "visibility");
      expect(visRow).toMatchObject({
        method: "replace",
        label: "Visibility",
        controlled: false,
        value: "Public",
      });
    });

    test("recurses nested plain objects and falls back to last segment when missing label", () => {
      const change = {
        descriptive_metadata: {
          nested: {
            inner: "Value",
            more: {
              arr: [1, 2, 3],
            },
          },
        },
      };

      const rows = toRows(change, "delete");
      expect(rows.map((r) => r.path).sort()).toEqual(
        [
          "descriptive_metadata.nested.inner",
          "descriptive_metadata.nested.more.arr",
        ].sort(),
      );

      const inner = rows.find(
        (r) => r.path === "descriptive_metadata.nested.inner",
      );
      expect(inner).toMatchObject({
        method: "delete",
        label: "inner", // fallback
        controlled: false,
        value: "Value",
      });

      const arr = rows.find(
        (r) => r.path === "descriptive_metadata.nested.more.arr",
      );
      expect(arr).toMatchObject({
        method: "delete",
        label: "arr", // fallback
        controlled: false,
        value: [1, 2, 3],
      });
    });

    test("does not descend into arrays (keeps them intact at parent path)", () => {
      const change = {
        descriptive_metadata: {
          description: ["a", "b", "c"],
          complex: [{ x: 1 }, { y: 2 }],
        },
      };

      const rows = toRows(change, "add");
      expect(rows.map((r) => r.path).sort()).toEqual(
        [
          "descriptive_metadata.description",
          "descriptive_metadata.complex",
        ].sort(),
      );

      const desc = rows.find(
        (r) => r.path === "descriptive_metadata.description",
      );
      const complex = rows.find(
        (r) => r.path === "descriptive_metadata.complex",
      );

      expect(desc && desc.controlled).toBe(false);
      expect(complex && complex.controlled).toBe(false);
    });
  });
});
