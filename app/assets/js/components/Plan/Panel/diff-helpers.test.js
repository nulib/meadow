jest.mock("@js/components/Plan/fields", () => {
  const WORK_FIELDS = {
    accessionNumber: "Accession Number",
    descriptive_metadata: {
      title: "Title",
      description: "Description",
      subject: "Subject",
      creator: "Creator",
      rights_statement: "Rights Statement",
      license: "License",
      notes: "Notes",
      related_url: "Related URL",
      date_created: "Date Created",
    },
    visibility: "Visibility",
  };

  const CONTROLLED_TERM_FIELDS = new Set([
    "descriptive_metadata.subject",
    "descriptive_metadata.creator",
  ]);

  const CODED_TERM_FIELDS = new Set([
    "descriptive_metadata.license",
    "descriptive_metadata.rights_statement",
  ]);

  const NESTED_CODED_TERM_FIELDS = new Set([
    "descriptive_metadata.notes",
    "descriptive_metadata.related_url",
  ]);

  const TEXT_SINGLE_FIELDS = new Set(["descriptive_metadata.title"]);

  const TEXT_ARRAY_FIELDS = new Set([
    "descriptive_metadata.description",
    "descriptive_metadata.date_created",
  ]);

  return {
    WORK_FIELDS,
    CONTROLLED_TERM_FIELDS,
    CODED_TERM_FIELDS,
    NESTED_CODED_TERM_FIELDS,
    TEXT_SINGLE_FIELDS,
    TEXT_ARRAY_FIELDS,
  };
});

import {
  toArray,
  isControlled,
  getFieldLabel,
  toRows,
  snakeToCamelPath,
  getCurrentValue,
  normalizeItem,
  computeRowDiff,
} from "./diff-helpers";

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

  // -----------------------------------------------------------------------
  // snakeToCamelPath
  // -----------------------------------------------------------------------
  describe("snakeToCamelPath", () => {
    test("converts a simple snake_case segment", () => {
      expect(snakeToCamelPath("visibility")).toBe("visibility");
      expect(snakeToCamelPath("accession_number")).toBe("accessionNumber");
    });

    test("converts each segment in a dotted path independently", () => {
      expect(snakeToCamelPath("descriptive_metadata.related_url")).toBe(
        "descriptiveMetadata.relatedUrl",
      );
      expect(snakeToCamelPath("descriptive_metadata.date_created")).toBe(
        "descriptiveMetadata.dateCreated",
      );
      expect(snakeToCamelPath("descriptive_metadata.rights_statement")).toBe(
        "descriptiveMetadata.rightsStatement",
      );
    });

    test("leaves already-camelCase paths unchanged", () => {
      expect(snakeToCamelPath("descriptiveMetadata.title")).toBe(
        "descriptiveMetadata.title",
      );
    });
  });

  // -----------------------------------------------------------------------
  // getCurrentValue
  // -----------------------------------------------------------------------
  describe("getCurrentValue", () => {
    const work = {
      descriptiveMetadata: {
        title: "Test Work",
        subject: [
          { term: { id: "s1", label: "Maps" } },
          { term: { id: "s2", label: "Photographs" } },
        ],
        relatedUrl: [
          { url: "https://example.com", label: { label: "Example" } },
        ],
      },
      visibility: "open",
    };

    test("returns a top-level scalar field", () => {
      expect(getCurrentValue("visibility", work)).toBe("open");
    });

    test("returns a nested scalar field (snake_case path → camelCase work)", () => {
      expect(getCurrentValue("descriptive_metadata.title", work)).toBe(
        "Test Work",
      );
    });

    test("returns a nested array field", () => {
      expect(getCurrentValue("descriptive_metadata.subject", work)).toEqual(
        work.descriptiveMetadata.subject,
      );
    });

    test("returns a deeply nested field", () => {
      expect(getCurrentValue("descriptive_metadata.related_url", work)).toEqual(
        work.descriptiveMetadata.relatedUrl,
      );
    });

    test("returns undefined for a missing path", () => {
      expect(
        getCurrentValue("descriptive_metadata.nonexistent", work),
      ).toBeUndefined();
    });

    test("returns undefined when work is null/undefined", () => {
      expect(
        getCurrentValue("descriptive_metadata.title", null),
      ).toBeUndefined();
      expect(
        getCurrentValue("descriptive_metadata.title", undefined),
      ).toBeUndefined();
    });
  });

  // -----------------------------------------------------------------------
  // normalizeItem — controlled term id handling
  // -----------------------------------------------------------------------
  describe("normalizeItem (controlled terms)", () => {
    test("term object: id is carried through", () => {
      const item = {
        term: { id: "http://vocab.getty.edu/aat/300132348", label: "Maps" },
      };
      const result = normalizeItem("descriptive_metadata.subject", item);
      expect(result.key).toBe("http://vocab.getty.edu/aat/300132348");
      expect(result.display).toBe("Maps");
      expect(result.id).toBe("http://vocab.getty.edu/aat/300132348");
    });

    test("term plain string: no id field", () => {
      const item = { term: "Aerial views" };
      const result = normalizeItem("descriptive_metadata.subject", item);
      expect(result.display).toBe("Aerial views");
      expect(result.id).toBeUndefined();
    });

    test("non-controlled fields do not carry id", () => {
      const result = normalizeItem(
        "descriptive_metadata.description",
        "Some description line",
      );
      expect(result.id).toBeUndefined();
    });
  });

  // -----------------------------------------------------------------------
  // computeRowDiff
  // -----------------------------------------------------------------------
  describe("computeRowDiff", () => {
    // Helper to build a minimal row
    const row = (path, method, value) => ({
      id: `${method}-${path}`,
      method,
      path,
      label: path.split(".").pop(),
      value,
      controlled: false,
    });

    // ---- coded term (scalar) ----
    test("coded term replace: scalar with label", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.license", "replace", {
          id: "cc-by",
          label: "CC BY",
        }),
        { id: "cc-zero", label: "CC0" },
      );
      expect(result).toEqual({
        kind: "scalar",
        current: "CC0",
        resulting: "CC BY",
        changed: true,
      });
    });

    test("coded term replace: unchanged when same label", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.license", "replace", {
          id: "cc-by",
          label: "CC BY",
        }),
        { id: "cc-by", label: "CC BY" },
      );
      expect(result.changed).toBe(false);
    });

    test("coded term delete: resulting is empty", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.rights_statement", "delete", {
          id: "x",
          label: "Some Rights",
        }),
        { id: "x", label: "Some Rights" },
      );
      expect(result).toEqual({
        kind: "scalar",
        current: "Some Rights",
        resulting: "",
        changed: true,
      });
    });

    // ---- text single (scalar) ----
    test("title replace: scalar string diff", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.title", "replace", "New Title"),
        "Old Title",
      );
      expect(result).toEqual({
        kind: "scalar",
        current: "Old Title",
        resulting: "New Title",
        changed: true,
      });
    });

    test("title replace with no current value: current is empty string", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.title", "replace", "New Title"),
        undefined,
      );
      expect(result).toEqual({
        kind: "scalar",
        current: "",
        resulting: "New Title",
        changed: true,
      });
    });

    // ---- text array (list) ----
    test("description add: new items appended as added", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.description", "add", ["New line"]),
        ["Existing line"],
      );
      expect(result.kind).toBe("list");
      expect(result.current).toEqual([
        { key: "Existing line", display: "Existing line", status: "unchanged" },
      ]);
      expect(result.resulting).toEqual([
        { key: "Existing line", display: "Existing line", status: "unchanged" },
        { key: "New line", display: "New line", status: "added" },
      ]);
    });

    test("description add: item already present is not duplicated as added", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.description", "add", ["Existing line"]),
        ["Existing line"],
      );
      expect(result.resulting).toEqual([
        { key: "Existing line", display: "Existing line", status: "unchanged" },
      ]);
    });

    test("description delete: matching items marked removed, resulting drops them", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.description", "delete", ["Remove me"]),
        ["Keep me", "Remove me"],
      );
      expect(result.kind).toBe("list");
      expect(result.current).toEqual([
        { key: "Keep me", display: "Keep me", status: "unchanged" },
        { key: "Remove me", display: "Remove me", status: "removed" },
      ]);
      expect(result.resulting).toEqual([
        { key: "Keep me", display: "Keep me", status: "unchanged" },
      ]);
    });

    test("description replace: old items not in delta removed, new items not in old added", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.description", "replace", ["New A", "Keep B"]),
        ["Keep B", "Old C"],
      );
      expect(result.kind).toBe("list");
      // current: Keep B unchanged, Old C removed
      expect(result.current).toEqual([
        { key: "Keep B", display: "Keep B", status: "unchanged" },
        { key: "Old C", display: "Old C", status: "removed" },
      ]);
      // resulting: New A added, Keep B unchanged
      expect(result.resulting).toEqual([
        { key: "New A", display: "New A", status: "added" },
        { key: "Keep B", display: "Keep B", status: "unchanged" },
      ]);
    });

    // ---- controlled terms ----
    test("controlled add: new term (object shape) appended as added — includes id", () => {
      const currentSubjects = [{ term: { id: "s1", label: "Maps" } }];
      const result = computeRowDiff(
        {
          ...row("descriptive_metadata.subject", "add", [
            { term: { id: "s2", label: "Photographs" } },
          ]),
          controlled: true,
        },
        currentSubjects,
      );
      expect(result.kind).toBe("list");
      expect(result.resulting).toEqual([
        { key: "s1", display: "Maps", id: "s1", status: "unchanged" },
        { key: "s2", display: "Photographs", id: "s2", status: "added" },
      ]);
    });

    test("controlled add: delta term given as plain string — no id", () => {
      const result = computeRowDiff(
        {
          ...row("descriptive_metadata.subject", "add", [
            { term: "Aerial views" },
          ]),
          controlled: true,
        },
        [{ term: { id: "s1", label: "Maps" } }],
      );
      expect(result.kind).toBe("list");
      const added = result.resulting.find((i) => i.status === "added");
      expect(added?.display).toBe("Aerial views");
      // Plain string terms have no authority id
      expect(added?.id).toBeUndefined();
    });

    test("controlled delete: matching term marked removed — includes id", () => {
      const result = computeRowDiff(
        {
          ...row("descriptive_metadata.subject", "delete", [
            { term: { id: "s2", label: "Photographs" } },
          ]),
          controlled: true,
        },
        [
          { term: { id: "s1", label: "Maps" } },
          { term: { id: "s2", label: "Photographs" } },
        ],
      );
      expect(result.kind).toBe("list");
      const removed = result.current.find((i) => i.status === "removed");
      expect(removed?.display).toBe("Photographs");
      expect(removed?.id).toBe("s2");
      expect(result.resulting).toHaveLength(1);
      expect(result.resulting[0].display).toBe("Maps");
      expect(result.resulting[0].id).toBe("s1");
    });

    // ---- date_created ----
    test("date_created add: work side single {edtf, humanized} normalized to array", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.date_created", "add", ["1897"]),
        { edtf: "1896", humanized: "1896" },
      );
      expect(result.kind).toBe("list");
      expect(result.current).toEqual([
        { key: "1896", display: "1896", status: "unchanged" },
      ]);
      expect(result.resulting).toEqual([
        { key: "1896", display: "1896", status: "unchanged" },
        { key: "1897", display: "1897", status: "added" },
      ]);
    });

    // ---- no current value ----
    test("add with no current value: current is empty, all delta items added", () => {
      const result = computeRowDiff(
        row("descriptive_metadata.description", "add", ["Line 1", "Line 2"]),
        undefined,
      );
      expect(result.kind).toBe("list");
      expect(result.current).toEqual([]);
      expect(result.resulting).toEqual([
        { key: "Line 1", display: "Line 1", status: "added" },
        { key: "Line 2", display: "Line 2", status: "added" },
      ]);
    });
  });
});
