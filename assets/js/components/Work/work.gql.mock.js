import { GET_WORK } from "../../components/Work/work.gql.js";
import { mockVisibility, mockWorkType } from "../../client-local";

export const mockWork = {
  id: "ABC123",
  accessionNumber: "Donohue_001",
  administrativeMetadata: {
    libraryUnit: { id: "Unit 1", label: "Unit 1" },
    preservationLevel: { id: 1, label: "Level 1" },
    projectCycle: "Project Cycle Name",
    projectDesc: ["New Project Description", "Another Project Description"],
    projectManager: ["New Project Manager", "Another Project Manager"],
    projectName: ["New Project Name", "Another project name"],
    projectProposer: ["New Project Proposer", "Another Project Proposer"],
    projectTaskNumber: ["New Project Task Number", "Another Project Task"],
    status: {
      id: "STARTED",
      label: "Started",
      scheme: "STATUS",
    },
    visibility: mockVisibility,
  },
  collection: {
    id: "1287312378238293126321308",
    title: "Collection 1232432 Name",
  },
  descriptiveMetadata: {
    abstract: ["New Abstract Test", "New Abstract Again"],
    alternateTitle: [],
    boxName: [],
    boxNumber: [],
    caption: [],
    catalogKey: [],
    contributor: [
      {
        role: {
          id: "art",
          label: "Artist",
          scheme: "MARC_RELATOR",
        },
        term: {
          id: "http://vocab.getty.edu/ulan/500029944",
          label: "Foot, D. D.",
        },
      },
    ],
    creator: [
      {
        term: {
          id: "https://theurioftheresource123",
          label: "This is the label",
        },
      },
    ],
    dateCreated: [{ edtf: "2010" }, { edtf: "2020" }],
    description: ["Work description here"],
    folderName: [],
    folderNumber: [],
    genre: [
      {
        term: {
          id: "http://vocab.getty.edu/aat/300417848",
          label: "Dralon (R)",
        },
      },
    ],
    identifier: [],
    keywords: [],
    language: [
      {
        term: {
          id: "https://theurioftheresource123",
          label: "This is the label",
        },
      },
    ],
    legacyIdentifier: [],
    license: {
      id: "http://creativecommons.org/publicdomain/mark/1.0/",
      label: "Public Domain Mark 1.0",
    },
    location: [
      {
        term: {
          id: "https://theurioftheresource123",
          label: "This is the label",
        },
      },
    ],
    notes: [],
    physicalDescriptionMaterial: [],
    physicalDescriptionSize: [],
    provenance: [],
    publisher: [],
    relatedUrl: [],
    relatedMaterial: [],
    rightsHolder: [],
    rightsStatement: {
      id: "https://northwestern.edu",
      label: "The label",
    },
    scopeAndContents: [],
    series: [],
    source: [],
    stylePeriod: [
      {
        term: {
          id: "https://theurioftheresource123",
          label: "This is the label",
        },
      },
    ],
    subject: [
      {
        term: {
          id: "https://clint.biz",
          label: "veritatis omnis est",
        },
        role: {
          id: "geographical",
          label: "geographical",
          scheme: "SUBJECT",
        },
      },
    ],
    tableOfContents: [],
    technique: [
      {
        term: {
          id: "https://theurioftheresource123",
          label: "This is the label",
        },
      },
    ],
    title: "Work title here",
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
  ingestSheet: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    title: "Bar",
  },
  insertedAt: "2019-02-04T19:16:16",
  manifestUrl: "http://foobar",
  project: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    title: "Foo",
  },
  published: false,
  representativeImage: "http://foobar",
  updatedAt: "2019-12-02T22:22:16",
  visibility: mockVisibility(),
  workType: mockWorkType(),
};

const mockWork2 = {
  id: "ABC123",
  accessionNumber: "Donohue_002b",
  administrativeMetadata: {
    libraryUnit: null,
    preservationLevel: null,
    projectCycle: null,
    projectDesc: [],
    projectManager: [],
    projectName: [],
    projectProposer: [],
    projectTaskNumber: [],
    status: null,
  },
  collection: null,
  descriptiveMetadata: {
    source: [],
    title: "Work title here",
    scopeAndContents: [],
    notes: [],
    folderName: [],
    license: {
      id: "http://creativecommons.org/publicdomain/mark/1.0/",
      label: "Public Domain Mark 1.0",
    },
    rightsHolder: [],
    genre: [
      {
        term: {
          id: "http://vocab.getty.edu/aat/300417848",
          label: "Dralon (R)",
        },
      },
    ],
    catalogKey: [],
    legacyIdentifier: [],
    alternateTitle: [],
    contributor: [
      {
        role: {
          id: "art",
          label: "Artist",
          scheme: "MARC_RELATOR",
        },
        term: {
          id: "http://vocab.getty.edu/ulan/500029944",
          label: "Foot, D. D.",
        },
      },
    ],
    caption: [],
    boxName: [],
    physicalDescriptionMaterial: [],
    rightsStatement: {
      id: "http://rightsstatements.org/vocab/InC/1.0/",
      label: "In Copyright",
    },
    series: [],
    tableOfContents: [],
    location: [],
    identifier: [],
    creator: [
      {
        term: {
          id: "http://vocab.getty.edu/ulan/500467488",
          label: "Mccormick, B. B.",
        },
      },
    ],
    relatedMaterial: [],
    relatedUrl: [],
    provenance: [],
    folderNumber: [],
    keywords: [],
    description: ["Work description here"],
    language: [],
    stylePeriod: [],
    publisher: [],
    technique: [],
    abstract: ["New Abstract Test", "New Abstract Again"],
    physicalDescriptionSize: [],
    boxNumber: [],
    subject: [],
  },
  fileSets: [
    {
      accessionNumber: "Donohue_002_03b",
      id: "0afa26f5-78e0-4ccb-b96f-052034dbbe27",
      metadata: {
        description: "Photo, two children praying",
        label: "painting7.JPG",
        location:
          "s3://dev-preservation/0a/fa/26/f5/6b94a88f3a357a1fabec803412ebfaa8972c8f8784e25b723898035b3863f303",
        originalFilename: "painting7.JPG",
        sha256:
          "6b94a88f3a357a1fabec803412ebfaa8972c8f8784e25b723898035b3863f303",
      },
      role: "AM",
    },
    {
      accessionNumber: "Donohue_002_01b",
      id: "38620e42-7c71-4364-8123-8106db5fd31c",
      metadata: {
        description: "Photo, man with two children",
        label: "painting5.JPG",
        location:
          "s3://dev-preservation/38/62/0e/42/a2fe39ca86723eaecb9a6e2557c3daf4698e2e5d4b124c81ad557b5854376a5b",
        originalFilename: "painting5.JPG",
        sha256:
          "a2fe39ca86723eaecb9a6e2557c3daf4698e2e5d4b124c81ad557b5854376a5b",
      },
      role: "AM",
    },
    {
      accessionNumber: "Donohue_002_02b",
      id: "251a0c80-4dbe-48c5-a77b-bcf8c403591d",
      metadata: {
        description: "Verso",
        label: "painting6.JPG",
        location:
          "s3://dev-preservation/25/1a/0c/80/7c69abf311b0da097edc8c54d30e27b41b8fcbca7b5e962c86b8604c5072cfb6",
        originalFilename: "painting6.JPG",
        sha256:
          "7c69abf311b0da097edc8c54d30e27b41b8fcbca7b5e962c86b8604c5072cfb6",
      },
      role: "AM",
    },
  ],
  ingestSheet: {
    id: "4651c546-d017-4322-911d-69e113070046",
    title: "Ima sheet",
  },
  insertedAt: "2020-07-23T19:55:46.427354Z",
  manifestUrl:
    "https://devbox.library.northwestern.edu:9001/dev-pyramids/public/d4/d1/a6/67/-b/1d/e-/4d/8a/-8/b3/1-/fb/28/e2/8f/fa/2f-manifest.json",
  project: {
    id: "28745a38-efe6-4cca-9d93-a4792f7f72d1",
    title: "Adam project",
  },
  published: false,
  representativeImage:
    "https://devbox.library.northwestern.edu:8183/iiif/2/38620e42-7c71-4364-8123-8106db5fd31c",
  updatedAt: "2020-07-24T15:20:14.119629Z",
  visibility: {
    id: "RESTRICTED",
    label: "Private",
  },
  workType: {
    id: "IMAGE",
    label: "Image",
  },
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
      work: mockWork2,
    },
  },
};
