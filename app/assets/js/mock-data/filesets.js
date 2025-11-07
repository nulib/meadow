export const mockFileSets = [
  {
    accessionNumber: "Voyager:2569254_FILE_0",
    coreMetadata: {
      altText: "Sample alt text for image",
      description: "inu-dil-9d35d0ba-a84b-4e0a-99e6-9c6b548a46db.tif",
      digests: {
        sha256:
          "6be181760c0adb1f3425a0ae3438f3633b0baa9a6f74afa973c94ae6de6f45cb",
      },
      imageCaption: "Sample image caption",
      label: "inu-dil-9d35d0ba-a84b-4e0a-99e6-9c6b548a46db.jpg",
      location:
        "s3://dev-preservation/45/22/6a/50/6be181760c0adb1f3425a0ae3438f3633b0baa9a6f74afa973c94ae6de6f45cb",
      mimeType: "image/jpeg",
      originalFilename: "inu-dil-9d35d0ba-a84b-4e0a-99e6-9c6b548a46db.jpg",
    },
    id: "45226a50-87ca-443e-bc05-f47884e14505",
    group_with: null,
    representativeImageUrl:
      "https://iiif.dev.rdc.library.northwestern.edu/iiif/2/wildcat-dev/posters/6d6bb649-2a5c-40d2-8d1b-23835de1c40a",
    role: {
      id: "A",
      scheme: "FILE_SET_ROLE",
    },
  },
  {
    __typename: "FileSet",
    accessionNumber: "Voyager:2572813_FILE_0",
    coreMetadata: {
      __typename: "FileSetCoreMetadata",
      altText: "Alternative text for grouped image",
      description: "inu-dil-41913a91-037f-494b-9113-06004a8a98fb.tif",
      digests: {
        sha256:
          "1477fbefbeeb04f0d02ac3cbd9594df0d9e7edca993ec076272d7fea67ab26a8",
      },
      imageCaption: "Caption for grouped image",
      label: "inu-dil-41913a91-037f-494b-9113-06004a8a98fb.jpg",
      location:
        "s3://dev-preservation/10/9b/9a/5c/1477fbefbeeb04f0d02ac3cbd9594df0d9e7edca993ec076272d7fea67ab26a8",
      mimeType: "image/jpeg",
      originalFilename: "inu-dil-41913a91-037f-494b-9113-06004a8a98fb.jpg",
    },
    id: "109b9a5c-3c6f-4a98-b98b-12402b871dc7",
    group_with: "45226a50-87ca-443e-bc05-f47884e14505",
    representativeImageUrl:
      "https://iiif.dev.rdc.library.northwestern.edu/iiif/2/wildcat-dev/posters/6d6bb649-2a5c-40d2-8d1b-23835de1c40a",
    role: {
      id: "A",
      scheme: "FILE_SET_ROLE",
    },
  },
  {
    __typename: "FileSet",
    accessionNumber: "Voyager:2553177_FILE_0",
    coreMetadata: {
      __typename: "FileSetCoreMetadata",
      altText: "Third image alt text",
      description: "inu-dil-96e6d167-5022-42e7-9de7-7f851a866f44.tif",
      digests: {
        sha256:
          "f7f1324a418e2c7c6ef17c45fc14ec6ce5a6124e636cb96272a7f35dc72d9664",
      },
      imageCaption: "Third image caption",
      label: "inu-dil-96e6d167-5022-42e7-9de7-7f851a866f44.jpg",
      location:
        "s3://dev-preservation/d4/14/d3/d4/f7f1324a418e2c7c6ef17c45fc14ec6ce5a6124e636cb96272a7f35dc72d9664",
      mimeType: "image/jpeg",
      originalFilename: "inu-dil-96e6d167-5022-42e7-9de7-7f851a866f44.jpg",
    },
    id: "d414d3d4-b72c-49cc-b7cc-faa9bc0f256e",
    group_with: null,
    representativeImageUrl:
      "https://iiif.dev.rdc.library.northwestern.edu/iiif/2/wildcat-dev/posters/6d6bb649-2a5c-40d2-8d1b-23835de1c40a",
    role: {
      id: "A",
      scheme: "FILE_SET_ROLE",
    },
  },
  {
    __typename: "FileSet",
    id: "6d6bb649-2a5c-40d2-8d1b-23835de1c40a",
    accessionNumber: "asdf45764567",
    coreMetadata: {
      __typename: "FileSetCoreMetadata",
      altText: "Big Buck Bunny video alternative text",
      description: "asdf",
      imageCaption: "Video caption for Big Buck Bunny",
      label: "Big buck",
      location:
        "s3://adam-dev-preservation/6d/6b/b6/49/6d6bb649-2a5c-40d2-8d1b-23835de1c40a",
      mimeType: "video/mp4",
      originalFilename: "Big_Buck_Bunny_720_10s_1MB.mp4",
      digests: {
        __typename: "Digests",
        md5: "626cc0e47eda47c080553ac8d25c3d3d",
        sha1: null,
        sha256: null,
      },
    },
    extractedMetadata: "",
    insertedAt: "2024-05-10T15:54:20.611963Z",
    role: {
      __typename: "CodedTerm",
      id: "A",
      label: "Access",
    },
    representativeImageUrl:
      "https://iiif.dev.rdc.library.northwestern.edu/iiif/2/adam-dev/posters/6d6bb649-2a5c-40d2-8d1b-23835de1c40a",
    streamingUrl:
      "https://adam-dev-streaming.s3.amazonaws.com/6d/6b/b6/49/-2/a5/c-/40/d2/-8/d1/b-/23/83/5d/e1/c4/0a/6d6bb649-2a5c-40d2-8d1b-23835de1c40a.m3u8",
    structuralMetadata: {
      __typename: "FileSetStructuralMetadata",
      type: null,
      value: null,
    },
    updatedAt: "2024-05-10T15:57:25.290859Z",
  },
];
