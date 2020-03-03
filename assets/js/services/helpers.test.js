import {
  buildImageURL,
  escapeDoubleQuotes,
  formatDate,
  getClassFromIngestSheetStatus
} from "./helpers";

describe("Build Image URL function", () => {
  it("should return a URL containing correct IIIF params", () => {
    const expected =
      "http://localhost:8183/iiif/2/ABC123/square/500,500/0/default.jpg";
    const actual = buildImageURL("ABC123", "IIIF_SQUARE");
    expect(expected).toEqual(actual);
  });
  it("should return default URL for placeholder Image", () => {
    const expected = "/images/1280x960.png";
    const actual = buildImageURL("", "IIIF_SQUARE");
    expect(expected).toEqual(actual);
  });
});

it("should escape double quotes", () => {
  const expected = 'This is a %5C"doubleQuoted%5C" expression';
  const actual = escapeDoubleQuotes(`This is a "doubleQuoted" expression`);
  expect(expected).toMatch(actual);
});

describe("Convert String to Date function", () => {
  it("should format date", () => {
    const expected = "Feb 26, 2020 2:57 PM";
    const actual = formatDate("2020-02-26T14:57:09.263182Z");
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
