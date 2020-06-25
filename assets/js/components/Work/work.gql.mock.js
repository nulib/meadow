import { GET_WORK } from "../../components/Work/work.gql.js";
import { mockVisibility, mockWorkType } from "../../client-local";

export const mockWork = {
  accessionNumber: "Donohue_001",
  administrativeMetadata: {
    preservationLevel: { id: 1, label: "Level 1" },
  },
  collection: {
    id: "1287312378238293126321308",
    name: "Collection 1232432 Name",
  },
  descriptiveMetadata: {
    description: "Work description here",
    title: "Work title here",
    contributor: [
      {
        id: "https://kadin.org",
        label: "veniam et et",
        role: {
          id: "aut",
          label: "Author",
          scheme: "MARC_RELATOR",
        },
      },
    ],
    creator: [
      {
        id: "https://theurioftheresource123",
        label: "This is the label",
      },
    ],
    genre: [
      {
        id: "https://theurioftheresource123",
        label: "This is the label",
      },
    ],
    language: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    location: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    rightsStatement: {
      id: "https://northwestern.edu",
      label: "The label",
    },
    stylePeriod: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    subject: [
      {
        id: "https://clint.biz",
        label: "veritatis omnis est",
        role: {
          id: "geographical",
          label: "geographical",
          scheme: "SUBJECT",
          __typename: "ControlledTerm",
        },
        __typename: "ControlledTerm",
      },
    ],
    technique: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
  },
  fileSets: [
    {
      accessionNumber: "Donohue_001_04",
      id: "01E08T3EXBJX3PWDG22NSRE0BS",
      role: "AM",
      metadata: {
        description: "Letter, page 2, If these papers, verso, blank",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        sha256: "foobar",
      },
    },
    {
      accessionNumber: "Donohue_001_01",
      id: "01E08T3EW3TQ9T0AXCR6X9QDJW",
      role: "AM",
      metadata: {
        description: "Letter, page 1, Dear Sir, recto",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        sha256: "foobar",
      },
    },
    {
      accessionNumber: "Donohue_001_03",
      id: "01E08T3EWRPXMWW0B1NHZ56AW6",
      role: "AM",
      metadata: {
        description: "Letter, page 2, If these papers, recto",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        sha256: "foobar",
      },
    },
    {
      accessionNumber: "Donohue_001_02",
      id: "01E08T3EWFJB35RY3RVR65AXMK",
      role: "AM",
      metadata: {
        description: "Letter, page 1, Dear Sir, verso, blank",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        sha256: "foobar",
      },
    },
  ],
  id: "ABC123",
  insertedAt: "2019-02-04T19:16:16",
  published: false,
  visibility: mockVisibility(),
  workType: mockWorkType(),
  project: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    name: "Foo",
  },
  sheet: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    name: "Bar",
  },
  updatedAt: "2019-12-02T22:22:16",
  manifestUrl: "http://foobar",
  representativeImage: "http://foobar",
};

export const getWorkMock = {
  request: {
    query: GET_WORK,
    variables: {
      id: "ABC123",
    },
  },
  result: {
    data: {
      work: mockWork,
    },
  },
};
