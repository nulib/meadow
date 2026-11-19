import {
  DEFAULT_SEARCH_SORT,
  SEARCH_SORT_FIELDS,
  SEARCH_SORT_STORAGE_KEY,
  buildSearchSort,
  normalizeSearchSort,
  readStoredSearchSort,
  searchSortForField,
  storeSearchSort,
  toggleSearchSortDirection,
} from "./search-sort";

describe("search sort", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("defines unique field keys and labels", () => {
    const keys = SEARCH_SORT_FIELDS.map((field) => field.key);
    const labels = SEARCH_SORT_FIELDS.map((field) => field.label);
    expect(new Set(keys).size).toEqual(keys.length);
    expect(new Set(labels).size).toEqual(labels.length);
    expect(keys).toContain(DEFAULT_SEARCH_SORT.field);
  });

  it("sorts Date Created by span start when oldest first and span end when newest first", () => {
    expect(
      buildSearchSort({ field: "date-created", direction: "asc" })[0],
    ).toEqual({
      date_created_start: { order: "asc", missing: "_last" },
    });
    expect(
      buildSearchSort({ field: "date-created", direction: "desc" })[0],
    ).toEqual({
      date_created_end: { order: "desc", missing: "_last" },
    });
  });

  it("appends a work id tiebreaker to every sort", () => {
    SEARCH_SORT_FIELDS.forEach((field) => {
      ["asc", "desc"].forEach((direction) => {
        const sort = buildSearchSort({ field: field.key, direction });
        expect(sort[sort.length - 1]).toEqual({ id: { order: "asc" } });
        expect(sort.length).toEqual(field.sort(direction).length + 1);
      });
    });
  });

  it("falls back to relevancy for unknown fields and fixes bad directions", () => {
    expect(normalizeSearchSort({ field: "nope", direction: "asc" })).toEqual(
      DEFAULT_SEARCH_SORT,
    );
    expect(normalizeSearchSort(null)).toEqual(DEFAULT_SEARCH_SORT);
    expect(
      normalizeSearchSort({ field: "title", direction: "sideways" }),
    ).toEqual({ field: "title", direction: "asc" });
    expect(buildSearchSort("nope")[0]).toEqual({ _score: { order: "desc" } });
  });

  it("picks each field's natural direction and toggles it", () => {
    expect(searchSortForField("modified")).toEqual({
      field: "modified",
      direction: "desc",
    });
    expect(searchSortForField("date-created")).toEqual({
      field: "date-created",
      direction: "asc",
    });
    expect(
      toggleSearchSortDirection(searchSortForField("date-created")),
    ).toEqual({ field: "date-created", direction: "desc" });
  });

  it("round trips the chosen sort through localStorage", () => {
    expect(readStoredSearchSort()).toEqual(DEFAULT_SEARCH_SORT);

    storeSearchSort({ field: "title", direction: "desc" });
    expect(JSON.parse(localStorage.getItem(SEARCH_SORT_STORAGE_KEY))).toEqual({
      field: "title",
      direction: "desc",
    });
    expect(readStoredSearchSort()).toEqual({
      field: "title",
      direction: "desc",
    });
  });

  it("ignores stored sorts that are unparseable or no longer exist", () => {
    localStorage.setItem(SEARCH_SORT_STORAGE_KEY, "Sort By Modified Date");
    expect(readStoredSearchSort()).toEqual(DEFAULT_SEARCH_SORT);

    localStorage.setItem(
      SEARCH_SORT_STORAGE_KEY,
      JSON.stringify({ field: "retired", direction: "asc" }),
    );
    expect(readStoredSearchSort()).toEqual(DEFAULT_SEARCH_SORT);
  });
});
