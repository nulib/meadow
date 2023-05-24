import {
  CREATE_WORK,
  DELETE_FILESET,
  GET_WORK,
  GET_WORK_TYPES,
  VERIFY_FILE_SETS,
  WORK_ARCHIVER_ENDPOINT,
} from "@js/components/Work/work.gql.js";
import { mockVisibility, mockWorkType } from "@js/client-local";

import { GET_IIIF_MANIFEST_HEADERS } from "./work.gql";

export const MOCK_WORK_ID = "ABC123";

export const mockWork = {
  id: MOCK_WORK_ID,
  accessionNumber: "Donohue_001",
  administrativeMetadata: {
    libraryUnit: { id: "Unit 1", label: "Unit 1" },
    preservationLevel: { id: 1, label: "Level 1" },
    projectCycle: "Project Cycle Name",
    projectDesc: ["New Project Description"],
    projectManager: ["New Project Manager"],
    projectName: ["New Project Name"],
    projectProposer: ["New Project Proposer"],
    projectTaskNumber: ["New Project Task Number"],
    status: {
      id: "NOT STARTED",
      label: "Not Started",
      scheme: "STATUS",
    },
    visibility: mockVisibility,
  },
  collection: {
    id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
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
    culturalContext: ["Ima context"],
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
      role: { id: "A", label: "Access" },
      coreMetadata: {
        description: "Letter, page 2, If these papers, verso, blank",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        mimeType: "image",
        originalFilename: "coffee.jpg",
        digests: {
          sha256: "foobar",
        },
      },
      extractedMetadata:
        '{"exif": {"tool": "exifr", "tool_version": "6.1.1", "value": {"Artist":"Artist Name","BitsPerSample":{"0":8,"1":8,"2":8},"Compression":1,"Copyright":"In Copyright","FillOrder":1,"ImageDescription":"inu-wint-58.6, 8/20/07, 11:16 AM,  8C, 9990x9750 (0+3570), 125%, bent 6 b/w adj,  1/30 s, R43.0, G4.4, B12.6","ImageHeight":1024,"ImageWidth":1024,"Make":"Better Light","Model":"Model Super8K","Orientation":"Horizontal (normal)","PhotometricInterpretation":2,"PlanarConfiguration":1,"ResolutionUnit":"inches","SamplesPerPixel":3,"Software":"Adobe Photoshop CC 2015.5 (Windows)","XResolution":72,"YResolution":72}}}',
      insertedAt: "2020-09-12T10:01:01",
      updatedAt: "2020-09-18T09:01:01",
    },
    {
      accessionNumber: "Donohue_001_01",
      id: "01E08T3EW3TQ9T0AXCR6X9QDJW",
      role: { id: "A", label: "Access" },
      coreMetadata: {
        description: "Letter, page 1, Dear Sir, recto",
        location: "s3://bucket/foo/bar",
        mimeType: "image",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        digests: {
          sha256: "foobar",
        },
      },
      extractedMetadata:
        '{"exif": {"tool": "exifr", "tool_version": "6.1.1", "value": {"Artist":"Artist Name","BitsPerSample":{"0":8,"1":8,"2":8},"Compression":1,"Copyright":"In Copyright","FillOrder":1,"ImageDescription":"inu-wint-58.6, 8/20/07, 11:16 AM,  8C, 9990x9750 (0+3570), 125%, bent 6 b/w adj,  1/30 s, R43.0, G4.4, B12.6","ImageHeight":1024,"ImageWidth":1024,"Make":"Better Light","Model":"Model Super8K","Orientation":"Horizontal (normal)","PhotometricInterpretation":2,"PlanarConfiguration":1,"ResolutionUnit":"inches","SamplesPerPixel":3,"Software":"Adobe Photoshop CC 2015.5 (Windows)","XResolution":72,"YResolution":72}}}',
      insertedAt: "2020-11-12T10:01:01",
      updatedAt: "2020-11-18T09:01:01",
    },
    {
      accessionNumber: "Donohue_001_03",
      id: "01E08T3EWRPXMWW0B1NHZ56AW6",
      role: { id: "A", label: "Access" },
      coreMetadata: {
        description: "Letter, page 2, If these papers, recto",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        mimeType: "image",
        label: "foo.tiff",
        digests: {
          sha256: "foobar",
        },
      },
      insertedAt: "2020-04-12T10:01:01",
      updatedAt: "2020-04-18T09:01:01",
    },
    {
      accessionNumber: "Donohue_001_02",
      id: "01E08T3EWFJB35RY3RVR65AXMK",
      role: { id: "A", label: "Access" },
      coreMetadata: {
        description: "Letter, page 1, Dear Sir, verso, blank",
        originalFilename: "coffee.jpg",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        mimeType: "image",
        digests: {
          sha256: "foobar",
        },
      },
      insertedAt: "2020-06-12T10:01:01",
      updatedAt: "2020-06-18T09:01:01",
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
    abstract: ["New Abstract Test", "New Abstract Again"],
    alternateTitle: [],
    ark: "ark123",
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
          id: "http://vocab.getty.edu/ulan/500467488",
          label: "Mccormick, B. B.",
        },
      },
    ],
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
    language: [],
    legacyIdentifier: [],
    license: {
      id: "http://creativecommons.org/publicdomain/mark/1.0/",
      label: "Public Domain Mark 1.0",
    },
    location: [],
    notes: [],
    physicalDescriptionMaterial: [],
    physicalDescriptionSize: [],
    provenance: [],
    publisher: [],
    relatedMaterial: [],
    relatedUrl: [],
    rightsHolder: [],
    rightsStatement: {
      id: "http://rightsstatements.org/vocab/InC/1.0/",
      label: "In Copyright",
    },
    scopeAndContents: [],
    series: [],
    source: [],
    stylePeriod: [],
    subject: [],
    tableOfContents: [],
    technique: [],
    title: "Work title here",
  },
  fileSets: [
    {
      accessionNumber: "Donohue_002_03b",
      coreMetadata: {
        description: "Photo, two children praying",
        digests: {
          sha256:
            "6b94a88f3a357a1fabec803412ebfaa8972c8f8784e25b723898035b3863f303",
        },
        label: "painting7.JPG",
        location:
          "s3://dev-preservation/0a/fa/26/f5/6b94a88f3a357a1fabec803412ebfaa8972c8f8784e25b723898035b3863f303",
        mimeType: "image",
        originalFilename: "painting7.JPG",
      },
      id: "0afa26f5-78e0-4ccb-b96f-052034dbbe27",
      insertedAt: "2020-07-12T10:01:01",
      role: {
        id: "A",
        label: "Access",
      },
      updatedAt: "2020-07-18T09:01:01",
    },
    {
      accessionNumber: "Donohue_002_01b",
      coreMetadata: {
        description: "Photo, man with two children",
        digests: {
          sha256:
            "a2fe39ca86723eaecb9a6e2557c3daf4698e2e5d4b124c81ad557b5854376a5b",
        },
        label: "painting5.JPG",
        location:
          "s3://dev-preservation/38/62/0e/42/a2fe39ca86723eaecb9a6e2557c3daf4698e2e5d4b124c81ad557b5854376a5b",
        originalFilename: "painting5.JPG",
      },
      id: "38620e42-7c71-4364-8123-8106db5fd31c",
      role: {
        id: "A",
        label: "Access",
      },
    },
    {
      accessionNumber: "Donohue_002_02b",
      coreMetadata: {
        description: "Verso",
        digests: {
          sha256:
            "7c69abf311b0da097edc8c54d30e27b41b8fcbca7b5e962c86b8604c5072cfb6",
        },
        label: "painting6.JPG",
        location:
          "s3://dev-preservation/25/1a/0c/80/7c69abf311b0da097edc8c54d30e27b41b8fcbca7b5e962c86b8604c5072cfb6",
        originalFilename: "painting6.JPG",
      },
      id: "251a0c80-4dbe-48c5-a77b-bcf8c403591d",
      role: {
        id: "A",
        label: "Access",
      },
    },
  ],
  id: MOCK_WORK_ID,
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
      id: MOCK_WORK_ID,
    },
  },
  result: {
    data: {
      work: mockWork2,
    },
  },
};

export const getWorkTypesMock = {
  request: {
    query: GET_WORK_TYPES,
  },
  result: {
    data: {
      codeList: [
        {
          id: "AUDIO",
          label: "Audio",
          scheme: "WORK_TYPE",
        },
        {
          id: "DOCUMENT",
          label: "Document",
          scheme: "WORK_TYPE",
        },
        {
          id: "IMAGE",
          label: "Image",
          scheme: "WORK_TYPE",
        },
        {
          id: "VIDEO",
          label: "Video",
          scheme: "WORK_TYPE",
        },
      ],
    },
  },
};

export const createWorkMock = {
  request: {
    query: CREATE_WORK,
    variables: {
      accessionNumber: "Donohue_001",
      title: "New mock work title",
      workType: {
        id: "IMAGE",
        scheme: "WORK_TYPE",
      },
    },
  },
  result: {
    data: {
      work: {
        accessionNumber: "Donohue_001",
        descriptiveMetadata: {
          title: "New mock work title",
        },
        id: MOCK_WORK_ID,
        workType: {
          id: "IMAGE",
          label: "Image",
        },
      },
    },
  },
};

export const deleteFilesetMock = {
  request: {
    query: DELETE_FILESET,
    variables: {
      fileSetId: MOCK_WORK_ID,
    },
  },
  result: {
    data: {
      deleteFileSet: {
        id: MOCK_WORK_ID,
      },
    },
  },
};

export const verifyFileSetsMock = {
  request: {
    query: VERIFY_FILE_SETS,
    variables: {
      workId: MOCK_WORK_ID,
    },
  },
  result: {
    data: {
      verifyFileSets: [
        {
          fileSetId: mockWork.fileSets[0].id,
          verified: true,
        },
        {
          fileSetId: mockWork.fileSets[1].id,
          verified: false,
        },
        {
          fileSetId: mockWork.fileSets[2].id,
          verified: true,
        },
        {
          fileSetId: mockWork.fileSets[3].id,
          verified: true,
        },
      ],
    },
  },
};

export const workArchiverEndpointMock = {
  request: {
    query: WORK_ARCHIVER_ENDPOINT,
  },
  result: {
    data: {
      workArchiverEndpoint: {
        url: "http://mockendpoint.com/",
      },
    },
  },
};

export const getIIIFManifestHeaders = {
  request: {
    query: GET_IIIF_MANIFEST_HEADERS,
    variables: {
      workId: MOCK_WORK_ID,
    },
  },
  result: {
    data: {
      iiifManifestHeaders: {
        manifestUrl: "",
        etag: "",
        lastModified: "",
        workId: MOCK_WORK_ID,
      },
    },
  },
};
