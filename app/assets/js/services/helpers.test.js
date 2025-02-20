import {
  escapeDoubleQuotes,
  formatDate,
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
  expect(isUrlValid("northwestern https://www.northwestern.edu")).toBe(false);

  expect(isUrlValid("www.google.cc")).toBe(true);
  expect(isUrlValid("www.google.co.uk")).toBe(true);
  expect(isUrlValid("http://www.northwestern.edu")).toBe(true);
  expect(isUrlValid("https://www.northwestern.edu")).toBe(true);
});

it("should return representative image URL", () => {
  expect(getImageUrl({ url: "www.northwestern.edu" })).toBe(
    "www.northwestern.edu",
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
      role: { label: "A", scheme: "FILE_SET_ROLE" },
      accessionNumber: "inu-fava-5145080_FILE_0",
      insertedAt: "2022-06-23T18:05:47.239216Z",
      coreMetadata: {
        __typename: "FileSetCoreMetadata",
        description: "inu-fava-5145080-6.tif",
        originalFilename: "A.jpg",
        label: "inu-fava-5145080-6.jpg",
        location:
          "s3://dev-preservation/23/57/ea/03/83397074acde5c737ede5ea7b09b267940d1ddba93eaef2456ae85c928e7abe2",
        digests: {
          sha256:
            "83397074acde5c737ede5ea7b09b267940d1ddba93eaef2456ae85c928e7abe2",
        },
      },
    },
    {
      id: "26357d25-b5e0-4e27-b683-c6844a13dc6b",
      role: { label: "A", scheme: "FILE_SET_ROLE" },
      accessionNumber: "inu-fava-5145080_FILE_1",
      insertedAt: "2025-08-17T18:05:47.239216Z",
      coreMetadata: {
        __typename: "FileSetCoreMetadata",
        description: "inu-fava-5145080-5.tif",
        originalFilename: "B.jpg",
        label: "inu-fava-5145080-5.jpg",
        location:
          "s3://dev-preservation/26/35/7d/25/033a20e54f4ef254749c0e554e0378ba96242be159c7ed6e8d57810297423f69",
        digests: {
          sha256:
            "033a20e54f4ef254749c0e554e0378ba96242be159c7ed6e8d57810297423f69",
        },
      },
    },
    {
      id: "0607a735-9f99-4d38-b75a-6c10027f0937",
      role: { label: "P", scheme: "FILE_SET_ROLE" },
      accessionNumber: "inu-fava-5145080_FILE_2",
      insertedAt: "2023-01-10T18:05:47.239216Z",
      coreMetadata: {
        __typename: "FileSetCoreMetadata",
        description: "inu-fava-5145080-1.tif",
        originalFilename: "C.jpg",
        label: "inu-fava-5145080-1.jpg",
        location:
          "s3://dev-preservation/06/07/a7/35/e3420d439e9770bdc804a19c559ca818120f67e81c303a92a33f774eab199056",
        digests: {
          sha256:
            "e3420d439e9770bdc804a19c559ca818120f67e81c303a92a33f774eab199056",
        },
      },
    },
  ];

  // Filename

  it("should order file sets in ascending order by filename", () => {
    const sorted = sortFileSets({
      order: "asc",
      orderBy: "filename",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].coreMetadata.originalFilename).toEqual("A.jpg");
    expect(sorted[1].coreMetadata.originalFilename).toEqual("B.jpg");
    expect(sorted[2].coreMetadata.originalFilename).toEqual("C.jpg");
  });

  it("should order file sets in descending order by filename", () => {
    const sorted = sortFileSets({
      order: "desc",
      orderBy: "filename",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].coreMetadata.originalFilename).toEqual("C.jpg");
    expect(sorted[1].coreMetadata.originalFilename).toEqual("B.jpg");
    expect(sorted[2].coreMetadata.originalFilename).toEqual("A.jpg");
  });

  // Created

  it("should order file sets in ascending order by created", () => {
    const sorted = sortFileSets({
      order: "asc",
      orderBy: "created",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].insertedAt).toEqual("2022-06-23T18:05:47.239216Z");
    expect(sorted[1].insertedAt).toEqual("2023-01-10T18:05:47.239216Z");
    expect(sorted[2].insertedAt).toEqual("2025-08-17T18:05:47.239216Z");
  });

  it("should order file sets in descending order by created", () => {
    const sorted = sortFileSets({
      order: "desc",
      orderBy: "created",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].insertedAt).toEqual("2025-08-17T18:05:47.239216Z");
    expect(sorted[1].insertedAt).toEqual("2023-01-10T18:05:47.239216Z");
    expect(sorted[2].insertedAt).toEqual("2022-06-23T18:05:47.239216Z");
  });

  // Accession Number

  it("should order file sets in ascending order by accessionNumber", () => {
    const sorted = sortFileSets({
      order: "asc",
      orderBy: "accessionNumber",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].accessionNumber).toEqual("inu-fava-5145080_FILE_0");
    expect(sorted[1].accessionNumber).toEqual("inu-fava-5145080_FILE_1");
    expect(sorted[2].accessionNumber).toEqual("inu-fava-5145080_FILE_2");
  });

  it("should order file sets in descending order by accessionNumber", () => {
    const sorted = sortFileSets({
      order: "desc",
      orderBy: "accessionNumber",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].accessionNumber).toEqual("inu-fava-5145080_FILE_2");
    expect(sorted[1].accessionNumber).toEqual("inu-fava-5145080_FILE_1");
    expect(sorted[2].accessionNumber).toEqual("inu-fava-5145080_FILE_0");
  });

  // Role

  it("should order file sets in ascending order by role", () => {
    const sorted = sortFileSets({
      order: "asc",
      orderBy: "role",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].role.label).toEqual("A");
    expect(sorted[1].role.label).toEqual("A");
    expect(sorted[2].role.label).toEqual("P");
  });

  it("should order file sets in descending order by role", () => {
    const sorted = sortFileSets({
      order: "desc",
      orderBy: "role",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].role.label).toEqual("P");
    expect(sorted[1].role.label).toEqual("A");
    expect(sorted[2].role.label).toEqual("A");
  });

  // ID

  it("should order file sets in ascending order by role", () => {
    const sorted = sortFileSets({
      order: "asc",
      orderBy: "id",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].id).toEqual("0607a735-9f99-4d38-b75a-6c10027f0937");
    expect(sorted[1].id).toEqual("2357ea03-9dd5-49f2-a88c-dfc9aa88be3c");
    expect(sorted[2].id).toEqual("26357d25-b5e0-4e27-b683-c6844a13dc6b");
  });

  it("should order file sets in descending order by role", () => {
    const sorted = sortFileSets({
      order: "desc",
      orderBy: "id",
      fileSets: originalFileSets,
      verifiedFileSets: [],
    });
    expect(sorted[0].id).toEqual("26357d25-b5e0-4e27-b683-c6844a13dc6b");
    expect(sorted[1].id).toEqual("2357ea03-9dd5-49f2-a88c-dfc9aa88be3c");
    expect(sorted[2].id).toEqual("0607a735-9f99-4d38-b75a-6c10027f0937");
  });

  // Verified

  it("should order file sets in ascending order by role", () => {
    const sorted = sortFileSets({
      order: "asc",
      orderBy: "verified",
      fileSets: originalFileSets,
      verifiedFileSets: ["2357ea03-9dd5-49f2-a88c-dfc9aa88be3c"],
    });
    expect(sorted[0].id).toEqual("26357d25-b5e0-4e27-b683-c6844a13dc6b");
    expect(sorted[1].id).toEqual("0607a735-9f99-4d38-b75a-6c10027f0937");
    expect(sorted[2].id).toEqual("2357ea03-9dd5-49f2-a88c-dfc9aa88be3c");
  });

  it("should order file sets in descending order by role", () => {
    const sorted = sortFileSets({
      order: "desc",
      orderBy: "verified",
      fileSets: originalFileSets,
      verifiedFileSets: ["2357ea03-9dd5-49f2-a88c-dfc9aa88be3c"],
    });
    expect(sorted[0].id).toEqual("2357ea03-9dd5-49f2-a88c-dfc9aa88be3c");
    expect(sorted[1].id).toEqual("26357d25-b5e0-4e27-b683-c6844a13dc6b");
    expect(sorted[2].id).toEqual("0607a735-9f99-4d38-b75a-6c10027f0937");
  });
});
