import {
  ARCHIVES_SPACE_IMPORT_PREVIEW_SUBSCRIPTION,
  IMPORT_ARCHIVES_SPACE_RESOURCE,
  LIST_ARCHIVES_SPACE_IMPORTS,
  SEARCH_ARCHIVES_SPACE_RESOURCES,
  START_ARCHIVES_SPACE_IMPORT_PREVIEW,
} from "./archivesSpace.gql";

export const MOCK_RESOURCE_URI = "/repositories/2/resources/63";
export const MOCK_RESOURCE_TITLE = "Berkeley Folk Music Festival";
export const MOCK_COLLECTION_ID = "01GENERATEDCOLLECTIONID999";
export const MOCK_PREVIEW_TOKEN = "cf858720-64ab-4a21-9780-85ed32d56334";

export const searchArchivesSpaceResourcesMock = {
  request: {
    query: SEARCH_ARCHIVES_SPACE_RESOURCES,
    variables: { query: "folk" },
  },
  result: {
    data: {
      archivesSpaceResourceSearch: {
        results: [
          {
            uri: MOCK_RESOURCE_URI,
            title: MOCK_RESOURCE_TITLE,
            identifier: "MS-63",
            importValidation: {
              importable: true,
              blockedReason: null,
              blockedCount: 0,
              blockedSamples: [],
            },
          },
          {
            uri: "/repositories/2/resources/64",
            title: "Folk Dance Society Records",
            identifier: "MS-64",
            importValidation: {
              importable: true,
              blockedReason: null,
              blockedCount: 0,
              blockedSamples: [],
            },
          },
        ],
        totalHits: 2,
      },
    },
  },
};

export const searchArchivesSpaceResourcesBlockedMock = {
  request: {
    query: SEARCH_ARCHIVES_SPACE_RESOURCES,
    variables: { query: "blocked" },
  },
  result: {
    data: {
      archivesSpaceResourceSearch: {
        results: [
          {
            uri: "/repositories/2/resources/65",
            title: "Already in Digital Collections",
            identifier: "MS-65",
            importValidation: {
              importable: false,
              blockedReason:
                "This finding aid already contains digital object links to Digital Collections/ARK records. Importing it would re-ingest Meadow records as source files.",
              blockedCount: 1,
              blockedSamples: [
                {
                  uri: "/repositories/2/archival_objects/2131",
                  title: "10, 79th & Wentworth, 1975-07-07",
                  fileUri: "https://n2t.net/ark:/81985/n2t14wd6q",
                },
              ],
            },
          },
        ],
        totalHits: 1,
      },
    },
  },
};

export const searchArchivesSpaceResourcesEmptyMock = {
  request: {
    query: SEARCH_ARCHIVES_SPACE_RESOURCES,
    variables: { query: "nothing" },
  },
  result: {
    data: {
      archivesSpaceResourceSearch: {
        results: [],
        totalHits: 0,
      },
    },
  },
};

export const listArchivesSpaceImportsMock = {
  request: {
    query: LIST_ARCHIVES_SPACE_IMPORTS,
  },
  result: {
    data: {
      archivesSpaceImports: [
        {
          id: "01IMPORT0000000000000001",
          archivesSpaceUri: MOCK_RESOURCE_URI,
          findingAidUrl: "https://findingaids.example.edu/63",
          syncStatus: "LINKED",
          workCount: 5,
          insertedAt: "2026-06-16T00:00:00Z",
          collection: {
            id: MOCK_COLLECTION_ID,
            title: MOCK_RESOURCE_TITLE,
          },
        },
      ],
    },
  },
};

export const listArchivesSpaceImportsEmptyMock = {
  request: {
    query: LIST_ARCHIVES_SPACE_IMPORTS,
  },
  result: {
    data: {
      archivesSpaceImports: [],
    },
  },
};

export const importArchivesSpaceResourceMock = {
  request: {
    query: IMPORT_ARCHIVES_SPACE_RESOURCE,
    variables: { resourceUri: MOCK_RESOURCE_URI, aiIngest: false },
  },
  result: {
    data: {
      importArchivesSpaceResource: {
        id: MOCK_COLLECTION_ID,
        title: MOCK_RESOURCE_TITLE,
        findingAidUrl: "https://findingaids.example.edu/63",
      },
    },
  },
};

export const startArchivesSpaceImportPreviewMock = {
  request: {
    query: START_ARCHIVES_SPACE_IMPORT_PREVIEW,
    variables: { resourceUri: MOCK_RESOURCE_URI },
  },
  result: {
    data: {
      archivesSpaceStartImportPreview: {
        token: MOCK_PREVIEW_TOKEN,
        status: "PENDING",
      },
    },
  },
};

export const archivesSpaceImportPreviewSubscriptionMock = {
  request: {
    query: ARCHIVES_SPACE_IMPORT_PREVIEW_SUBSCRIPTION,
    variables: { token: MOCK_PREVIEW_TOKEN },
  },
  result: {
    data: {
      archivesSpaceImportPreview: {
        token: MOCK_PREVIEW_TOKEN,
        status: "COMPLETE",
        estimatedCost: 4.2,
        sampleCount: 2,
        totalCount: 10,
        error: null,
        previews: [
          {
            workAccessionNumber: "aspace-preview:abc123",
            title: "Poster 1, 1968",
            description:
              "A concert poster for the Berkeley Folk Music Festival.",
            thumbnail: "ZmFrZQ==",
            subjects: [
              { id: "http://example.edu/fast/1", label: "Folk music" },
            ],
          },
          {
            workAccessionNumber: "aspace-preview:def456",
            title: "Program, 1968",
            description: "The printed program for the 1968 festival.",
            thumbnail: "ZmFrZQ==",
            subjects: [
              { id: "http://example.edu/fast/2", label: "Music festivals" },
            ],
          },
        ],
      },
    },
  },
};

export const importArchivesSpaceResourceAiMock = {
  request: {
    query: IMPORT_ARCHIVES_SPACE_RESOURCE,
    variables: { resourceUri: MOCK_RESOURCE_URI, aiIngest: true },
  },
  result: {
    data: {
      importArchivesSpaceResource: {
        id: MOCK_COLLECTION_ID,
        title: MOCK_RESOURCE_TITLE,
        findingAidUrl: "https://findingaids.example.edu/63",
      },
    },
  },
};
