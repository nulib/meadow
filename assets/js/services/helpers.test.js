import {
  buildImageURL,
  escapeDoubleQuotes,
  formatDate,
  getClassFromIngestSheetStatus,
  isUrlValid,
  getImageUrl,
} from "./helpers";

it("should escape double quotes", () => {
  const expected = 'This is a %5C"doubleQuoted%5C" expression';
  const actual = escapeDoubleQuotes(`This is a "doubleQuoted" expression`);
  expect(expected).toMatch(actual);
});

it("should validate URL pattern", () => {
  expect(isUrlValid("htttp://northwestern.edu")).toBe(false);
  expect(isUrlValid("ww.northwestern.edu")).toBe(false);
  expect(isUrlValid("northwestern.edu")).toBe(false);

  expect(isUrlValid("www.google.cc")).toBe(true);
  expect(isUrlValid("www.google.co.uk")).toBe(true);
  expect(isUrlValid("http://www.northwestern.edu")).toBe(true);
  expect(isUrlValid("https://www.northwestern.edu")).toBe(true);
});

it("should return representative image URL", () => {
  expect(getImageUrl({ url: "www.northwestern.edu" })).toBe(
    "www.northwestern.edu"
  );
  expect(getImageUrl({})).toBe("");
  expect(getImageUrl("www.northwestern.edu")).toBe("www.northwestern.edu");
  expect(getImageUrl()).toBe("");
});

describe("Convert String to Date function", () => {
  it("should format date", () => {
    const expected = "Feb 26, 2020 2:57 PM";
    const actual = formatDate("2020-02-26T20:57:09.263182Z");
    expect(expected).toEqual(actual);
  });
  it("should NOT format date", () => {
    const actual = formatDate("");
    expect(actual).toBe("");
  });
});

describe("IngestSheet status CSS-Class function", () => {
  it("should return is-danger for ROW_FAIL", () => {
    const expected = "is-danger";
    const actual = getClassFromIngestSheetStatus("ROW_FAIL");
    expect(expected).toEqual(actual);
  });
  it("should return is-danger for FILE_FAIL", () => {
    const expected = "is-danger";
    const actual = getClassFromIngestSheetStatus("FILE_FAIL");
    expect(expected).toEqual(actual);
  });
  it("should return is-warning for UPLOADED", () => {
    const expected = "is-warning";
    const actual = getClassFromIngestSheetStatus("UPLOADED");
    expect(expected).toEqual(actual);
  });
  it("should return is-success for COMPLETED", () => {
    const expected = "is-success";
    const actual = getClassFromIngestSheetStatus("COMPLETED");
    expect(expected).toEqual(actual);
  });
  it("should return is-success & is-light for APPROVED", () => {
    const expected = "is-success is-light";
    const actual = getClassFromIngestSheetStatus("APPROVED");
    expect(expected).toEqual(actual);
  });
  it("should return is-success & is-light for VALID", () => {
    const expected = "is-success is-light";
    const actual = getClassFromIngestSheetStatus("VALID");
    expect(expected).toEqual(actual);
  });
  it("should return empty", () => {
    const actual = getClassFromIngestSheetStatus();
    expect(actual).toBe("");
  });
});
