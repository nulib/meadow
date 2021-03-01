import {
  escapeDoubleQuotes,
  formatDate,
  getClassFromIngestSheetStatus,
  isUrlValid,
  getImageUrl,
  sortFileSets,
  sortItemsArray,
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

describe("Sort any array of objects", () => {
  const itemsArray = [
    {
      id: 1,
      title: "XYZ",
    },
    {
      id: 2,
      title: "ABC",
    },
    {
      id: 3,
      title: "PQR",
    },
  ];
  it("should order Array in ascending order", () => {
    const sorted = sortItemsArray(itemsArray, "title");
    expect(sorted[0].title).toEqual("ABC");
    expect(sorted[2].title).toEqual("XYZ");
  });

  it("should order Array in descending order", () => {
    const sorted = sortItemsArray(itemsArray, "title", "desc");
    expect(sorted[0].title).toEqual("XYZ");
    expect(sorted[2].title).toEqual("ABC");
  });
});

describe("Sort file sets", () => {
  const originalFileSets = [
    {
      id: "2357ea03-9dd5-49f2-a88c-dfc9aa88be3c",
      role: { id: "A", scheme: "FILE_SET_ROLE" },
      accessionNumber: "inu-fava-5145080_FILE_0",
      metadata: {
        __typename: "FileSetMetadata",
        description: "inu-fava-5145080-6.tif",
        originalFilename: "BBBBBBB.jpg",
        label: "inu-fava-5145080-6.jpg",
        location:
          "s3://dev-preservation/23/57/ea/03/83397074acde5c737ede5ea7b09b267940d1ddba93eaef2456ae85c928e7abe2",
        sha256:
          "83397074acde5c737ede5ea7b09b267940d1ddba93eaef2456ae85c928e7abe2",
      },
    },
    {
      id: "26357d25-b5e0-4e27-b683-c6844a13dc6b",
      role: { id: "A", scheme: "FILE_SET_ROLE" },
      accessionNumber: "inu-fava-5145080_FILE_1",
      metadata: {
        __typename: "FileSetMetadata",
        description: "inu-fava-5145080-5.tif",
        originalFilename: "CCCCCC.jpg",
        label: "inu-fava-5145080-5.jpg",
        location:
          "s3://dev-preservation/26/35/7d/25/033a20e54f4ef254749c0e554e0378ba96242be159c7ed6e8d57810297423f69",
        sha256:
          "033a20e54f4ef254749c0e554e0378ba96242be159c7ed6e8d57810297423f69",
      },
    },
    {
      id: "0607a735-9f99-4d38-b75a-6c10027f0937",
      role: { id: "A", scheme: "FILE_SET_ROLE" },
      accessionNumber: "inu-fava-5145080_FILE_2",
      metadata: {
        __typename: "FileSetMetadata",
        description: "inu-fava-5145080-1.tif",
        originalFilename: "AAAAA.jpg",
        label: "inu-fava-5145080-1.jpg",
        location:
          "s3://dev-preservation/06/07/a7/35/e3420d439e9770bdc804a19c559ca818120f67e81c303a92a33f774eab199056",
        sha256:
          "e3420d439e9770bdc804a19c559ca818120f67e81c303a92a33f774eab199056",
      },
    },
  ];

  it("should order file sets in ascending order", () => {
    const sorted = sortFileSets({ fileSets: originalFileSets });
    expect(sorted[0].metadata.originalFilename).toEqual("AAAAA.jpg");
    expect(sorted[2].metadata.originalFilename).toEqual("CCCCCC.jpg");
  });

  it("should order file sets in descending order", () => {
    const sorted = sortFileSets({ order: "desc", fileSets: originalFileSets });
    expect(sorted[2].metadata.originalFilename).toEqual("AAAAA.jpg");
    expect(sorted[0].metadata.originalFilename).toEqual("CCCCCC.jpg");
  });
});
