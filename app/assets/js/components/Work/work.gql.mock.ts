import {
  CREATE_WORK,
  DELETE_FILESET,
  GET_WORK,
  GET_WORK_TYPES,
  VERIFY_FILE_SETS,
  WORK_ARCHIVER_ENDPOINT,
} from "./work.gql.js";

import { type Work } from "@nulib/dcapi-types";

export const MOCK_WORK_ID = "ABC123";

export const mockWork: Work = {
  abstract: ["New Abstract Test", "New Abstract Again"],
  accession_number: "Donohue_001",
  alternate_title: [],
  box_name: [],
  box_number: [],
  caption: [],
  catalog_key: [],
  collection: {
    description: "Postcards with views of Evanston.",
    id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
    title: "Collection 1232432 Name",
  },
  contributor: [
    {
      facet:
        "http://id.loc.gov/authorities/names/n91114928|ctg|Metallica (Musical group) (Cartographer)",
      id: "http://id.loc.gov/authorities/names/n91114928",
      label: "Metallica (Musical group)",
      label_with_role: "Metallica (Musical group) (Cartographer)",
      role: "Cartographer",
      variants: [],
    },
  ],
  creator: [
    {
      facet:
        "http://id.loc.gov/authorities/names/no2011059409||Dessa (Vocalist)",
      id: "http://id.loc.gov/authorities/names/no2011059409",
      label: "Dessa (Vocalist)",
      variants: [
        "Dessa, 1981-",
        "Wander, Dessa, 1981-",
        "Dessa Darling",
        "Wander, Margret",
      ],
    },
    {
      facet: "http://id.worldcat.org/fast/1152763||Tornadoes",
      id: "http://id.worldcat.org/fast/1152763",
      label: "Tornadoes",
      variants: [],
    },
  ],
  cultural_context: ["Ima context"],
  date_created: ["2010", "2020"],
  description: ["Work description here"],
  file_sets: [
    {
      accession_number: "Donohue_001_04",
      description: "Letter, page 2, If these papers, verso, blank",
      digests: {
        sha256: "foobar",
      },
      label: "foo.tiff",
      location: "s3://bucket/foo/bar",
      mime_type: "image",
      original_filename: "coffee.jpg",
      extracted_metadata:
        '{"exif": {"tool": "exifr", "tool_version": "6.1.1", "value": {"Artist":"Artist Name","BitsPerSample":{"0":8,"1":8,"2":8},"Compression":1,"Copyright":"In Copyright","FillOrder":1,"ImageDescription":"inu-wint-58.6, 8/20/07, 11:16 AM,  8C, 9990x9750 (0+3570), 125%, bent 6 b/w adj,  1/30 s, R43.0, G4.4, B12.6","ImageHeight":1024,"ImageWidth":1024,"Make":"Better Light","Model":"Model Super8K","Orientation":"Horizontal (normal)","PhotometricInterpretation":2,"PlanarConfiguration":1,"ResolutionUnit":"inches","SamplesPerPixel":3,"Software":"Adobe Photoshop CC 2015.5 (Windows)","XResolution":72,"YResolution":72}}}',
      id: "01E08T3EXBJX3PWDG22NSRE0BS",
      create_date: "2020-09-12T10:01:01",
      role: "Access",
      modified_date: "2020-09-18T09:01:01",
    },
    {
      accession_number: "Donohue_001_01",
      description: "Letter, page 1, Dear Sir, recto",
      digests: {
        sha256: "foobar",
      },
      label: "foo.tiff",
      location: "s3://bucket/foo/bar",
      mime_type: "image",
      original_filename: "coffee.jpg",
      extracted_metadata:
        '{"exif": {"tool": "exifr", "tool_version": "6.1.1", "value": {"Artist":"Artist Name","BitsPerSample":{"0":8,"1":8,"2":8},"Compression":1,"Copyright":"In Copyright","FillOrder":1,"ImageDescription":"inu-wint-58.6, 8/20/07, 11:16 AM,  8C, 9990x9750 (0+3570), 125%, bent 6 b/w adj,  1/30 s, R43.0, G4.4, B12.6","ImageHeight":1024,"ImageWidth":1024,"Make":"Better Light","Model":"Model Super8K","Orientation":"Horizontal (normal)","PhotometricInterpretation":2,"PlanarConfiguration":1,"ResolutionUnit":"inches","SamplesPerPixel":3,"Software":"Adobe Photoshop CC 2015.5 (Windows)","XResolution":72,"YResolution":72}}}',
      id: "01E08T3EW3TQ9T0AXCR6X9QDJW",
      create_date: "2020-11-12T10:01:01",
      role: "Access",
      modified_date: "2020-11-18T09:01:01",
    },
    {
      accession_number: "Donohue_001_03",
      description: "Letter, page 2, If these papers, recto",
      digests: {
        sha256: "foobar",
      },
      label: "foo.tiff",
      location: "s3://bucket/foo/bar",
      mime_type: "image",
      original_filename: "coffee.jpg",
      id: "01E08T3EWRPXMWW0B1NHZ56AW6",
      create_date: "2020-04-12T10:01:01",
      role: "Access",
      modified_date: "2020-04-18T09:01:01",
    },
    {
      accession_number: "Donohue_001_02",
      description: "Letter, page 1, Dear Sir, verso, blank",
      digests: {
        sha256: "foobar",
      },
      label: "foo.tiff",
      location: "s3://bucket/foo/bar",
      mime_type: "image",
      original_filename: "coffee.jpg",
      id: "01E08T3EWFJB35RY3RVR65AXMK",
      create_date: "2020-06-12T10:01:01",
      role: "Access",
      modified_date: "2020-06-18T09:01:01",
    },
  ],
  folder_name: [],
  folder_number: [],
  genre: [
    {
      id: "http://vocab.getty.edu/aat/300417848",
      facet: "genre",
      label: "Dralon (R)",
      variants: [],
    },
  ],
  id: MOCK_WORK_ID,
  identifier: [],
  ingest_sheet: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    title: "Bar",
  },
  create_date: "2019-02-04T19:16:16",
  keywords: [],
  language: [
    {
      id: "https://theurioftheresource123",
      label: "This is the label",
      facet: "http://id.loc.gov/vocabulary/languages/crh||Crimean Tatar",
      variants: [],
    },
  ],
  legacy_identifier: [],
  library_unit: "Faculty Collections",
  license: {
    id: "http://creativecommons.org/publicdomain/mark/1.0/",
    label: "Public Domain Mark 1.0",
  },
  location: [
    {
      facet: "https://sws.geonames.org/4999069/||Leland Township",
      id: "https://theurioftheresource123",
      label: "This is the label",
      variants: [],
    },
  ],
  iiif_manifest: "http://foobar",
  notes: [],
  physical_description_material: [],
  physical_description_size: [],
  preservation_level: "Level 1",
  project: {
    cycle: "Project Cycle Name",
    desc: "New Project Description",
    manager: "New Project Manager",
    name: "New Project Name",
    proposer: "New Project Proposer",
    task_number: "New Project Task Number",
  },
  provenance: [],
  published: false,
  publisher: [],
  reading_room: false,
  related_material: [],
  related_url: [],
  representative_file_set: {
    aspect_ratio: 1.33333,
    id: "076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
    url: "https://iiif.stack.rdc-staging.library.northwestern.edu/iiif/2/076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
  },
  rights_holder: [],
  rights_statement: {
    id: "https://northwestern.edu",
    label: "The label",
  },
  scope_and_contents: [],
  series: [],
  source: ["Mars"],
  status: "Not Started",
  style_period: [
    {
      facet:
        "http://vocab.getty.edu/aat/300018478||Qing (dynastic styles and periods)",
      id: "https://theurioftheresource123",
      label: "This is the label",
      variants: [
        "Ch'ing (dynastic styles and periods)",
        "Manchu (dynastic styles and periods)",
        "清朝",
      ],
    },
  ],
  subject: [
    {
      facet:
        "http://id.worldcat.org/fast/1902713|TOPICAL|Cats on postage stamps (Topical)",
      id: "http://id.worldcat.org/fast/1902713",
      label: "Cats on postage stamps",
      label_with_role: "Cats on postage stamps (Topical)",
      role: "Topical",
      variants: [],
    },
    {
      facet:
        "info:nul/6cba23b5-a91a-4c13-8398-54967b329d48|TOPICAL|Test Record Canary (Topical)",
      id: "info:nul/6cba23b5-a91a-4c13-8398-54967b329d48",
      label: "Test Record Canary",
      label_with_role: "Test Record Canary (Topical)",
      role: "Topical",
      variants: [],
    },
  ],
  table_of_contents: [],
  technique: [
    {
      facet:
        "http://vocab.getty.edu/aat/300053228||drypoint (printing process)",
      id: "http://vocab.getty.edu/aat/300053228",
      label: "drypoint (printing process)",
      variants: [
        "dry point (printing process)",
        "dry-point (printing process)",
        "point, dry (printing process)",
        "直接刻線法",
        "乾刻法",
        "銅版雕刻術",
        "銅版雕刻",
        "droge naald (procedé)",
      ],
    },
  ],
  title: "Work title here",
  modified_date: "2019-12-02T22:22:16",
  visibility: "Public",
  workType: "Image",
};

const mockWork2: Work = {
  abstract: ["New Abstract Test", "New Abstract Again"],
  accession_number: "Donohue_002b",
  alternate_title: [],
  ark: "ark123",
  box_name: [],
  box_number: [],
  caption: [],
  catalog_key: [],
  collection: null,
  contributor: [
    {
      facet:
        "http://id.loc.gov/authorities/names/n91114928|ctg|Metallica (Musical group) (Cartographer)",
      id: "http://id.loc.gov/authorities/names/n91114928",
      label: "Metallica (Musical group)",
      label_with_role: "Metallica (Musical group) (Cartographer)",
      role: "Cartographer",
      variants: [],
    },
  ],
  create_date: "2020-07-23T19:55:46.427354Z",
  creator: [
    {
      facet: "http://vocab.getty.edu/aat/300443944||photo editors",
      id: "http://vocab.getty.edu/aat/300443944",
      label: "photo editors",
      variants: ["photo editor", "editors, photo"],
    },
    {
      facet:
        "http://id.worldcat.org/fast/1717972||Schober, Franz von, 1796-1882",
      id: "http://id.worldcat.org/fast/1717972",
      label: "Schober, Franz von, 1796-1882",
      variants: [],
    },
  ],
  description: ["Work description here"],
  file_sets: [
    {
      accession_number: "Donohue_002_03b",
      description: "Photo, two children praying",
      digests: {
        sha256:
          "6b94a88f3a357a1fabec803412ebfaa8972c8f8784e25b723898035b3863f303",
      },
      id: "0afa26f5-78e0-4ccb-b96f-052034dbbe27",
      label: "painting7.JPG",
      location:
        "s3://dev-preservation/0a/fa/26/f5/6b94a88f3a357a1fabec803412ebfaa8972c8f8784e25b723898035b3863f303",
      mime_type: "image",
      modified_date: "2020-07-18T09:01:01",
      original_filename: "painting7.JPG",
      role: "Access",
    },
    {
      accession_number: "Donohue_002_01b",
      description: "Photo, man with two children",
      digests: {
        sha256:
          "a2fe39ca86723eaecb9a6e2557c3daf4698e2e5d4b124c81ad557b5854376a5b",
      },
      id: "38620e42-7c71-4364-8123-8106db5fd31c",
      label: "painting5.JPG",
      location:
        "s3://dev-preservation/38/62/0e/42/a2fe39ca86723eaecb9a6e2557c3daf4698e2e5d4b124c81ad557b5854376a5b",
      original_filename: "painting5.JPG",
      role: "Access",
    },
    {
      accession_number: "Donohue_002_02b",
      description: "Verso",
      digests: {
        sha256:
          "7c69abf311b0da097edc8c54d30e27b41b8fcbca7b5e962c86b8604c5072cfb6",
      },
      id: "251a0c80-4dbe-48c5-a77b-bcf8c403591d",
      label: "painting6.JPG",
      location:
        "s3://dev-preservation/25/1a/0c/80/7c69abf311b0da097edc8c54d30e27b41b8fcbca7b5e962c86b8604c5072cfb6",
      original_filename: "painting6.JPG",
      role: "Access",
    },
  ],
  folder_name: [],
  folder_number: [],
  genre: [
    {
      facet: "http://id.worldcat.org/fast/1919896||Biographies",
      id: "http://id.worldcat.org/fast/1919896",
      label: "Biographies",
      variants: [],
    },
    {
      facet: "http://id.worldcat.org/fast/1019337||Mice",
      id: "http://id.worldcat.org/fast/1019337",
      label: "Mice",
      variants: [],
    },
  ],
  id: MOCK_WORK_ID,
  identifier: [],
  ingest_sheet: {
    id: "4651c546-d017-4322-911d-69e113070046",
    title: "Ima sheet",
  },
  keywords: [],
  language: [],
  legacy_identifier: [],
  library_unit: null,
  license: {
    id: "http://creativecommons.org/publicdomain/mark/1.0/",
    label: "Public Domain Mark 1.0",
  },
  location: [],
  manifestUrl:
    "https://devbox.library.northwestern.edu:9001/dev-pyramids/public/d4/d1/a6/67/-b/1d/e-/4d/8a/-8/b3/1-/fb/28/e2/8f/fa/2f-manifest.json",
  modified_date: "2020-07-24T15:20:14.119629Z",
  notes: [],
  physical_description_material: [],
  physical_description_size: [],
  preservation_level: null,
  project: {
    cycle: null,
    desc: null,
    manager: "Nicole",
    name: "Adam project",
    proposer: null,
    task_number: null,
  },
  provenance: [],
  published: false,
  publisher: [],
  reading_room: false,
  related_material: [],
  related_url: [],
  representative_file_set: {
    aspect_ratio: 1.33333,
    id: "076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
    url: "https://iiif.stack.rdc-staging.library.northwestern.edu/iiif/2/076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
  },
  rights_holder: [],
  rights_statement: {
    id: "http://rightsstatements.org/vocab/InC/1.0/",
    label: "In Copyright",
  },
  scope_and_contents: [],
  series: [],
  source: [],
  status: null,
  style_period: [],
  subject: [],
  table_of_contents: [],
  technique: [],
  title: "Work title here",
  visibility: "Private",
  workType: "Image",
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
      accession_number: "Donohue_001",
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
        accession_number: "Donohue_001",
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
          fileSetId: mockWork.file_sets[0].id,
          verified: true,
        },
        {
          fileSetId: mockWork.file_sets[1].id,
          verified: false,
        },
        {
          fileSetId: mockWork.file_sets[2].id,
          verified: true,
        },
        {
          fileSetId: mockWork.file_sets[3].id,
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
