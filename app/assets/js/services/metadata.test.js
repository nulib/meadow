import * as metadata from "./metadata";

describe("getBatchMultiValueDataFromForm()", () => {
  // Append
  const appendFormValues = {
    title: "",
    "alternateTitle--editType": "append",
    "description--editType": "append",
    "dateCreated--editType": "append",
    rightsStatement: "",
    "abstract--editType": "append",
    "caption--editType": "append",
    "keywords--editType": "append",
    "tableOfContents--editType": "append",
    "boxName--editType": "append",
    "boxNumber--editType": "append",
    "folderName--editType": "append",
    "folderNumber--editType": "append",
    alternateTitle: [
      {
        metadataItem: "Alt title 1",
      },
      {
        metadataItem: "Alt title 2",
      },
    ],
  };
  const replaceFormValues = {
    ...appendFormValues,
    "alternateTitle--editType": "replace",
  };
  const deleteFormValues = {
    ...appendFormValues,
    "alternateTitle--editType": "delete",
  };
  const appendExpected = {
    add: {
      alternateTitle: ["Alt title 1", "Alt title 2"],
    },
    replace: {},
  };
  const replaceExpected = {
    add: {},
    replace: {
      alternateTitle: ["Alt title 1", "Alt title 2"],
    },
  };
  const deleteExpected = {
    add: {},
    replace: {
      alternateTitle: [],
    },
  };
  expect(metadata.getBatchMultiValueDataFromForm(appendFormValues)).toEqual(
    appendExpected
  );
  expect(metadata.getBatchMultiValueDataFromForm(replaceFormValues)).toEqual(
    replaceExpected
  );
  expect(metadata.getBatchMultiValueDataFromForm(deleteFormValues)).toEqual(
    deleteExpected
  );
});

describe("prepControlledTermInput()", () => {
  const controlledTerm = {
    hasRole: true,
    label: "Contributor",
    name: "contributor",
    scheme: "MARC_RELATOR",
  };
  const formItems = [
    {
      roleId: "asg",
      authority: "loc",
      termId: "http://vocab.getty.edu/ulan/500276588",
      label: "Getty Lee",
    },
    {
      roleId: "arc",
      authority: "getty",
      termId: "http://vocab.getty.edu/ulan/500029944",
      label: "Foot, D. D.",
    },
  ];

  it("preps controlled term with role form data successfully", () => {
    const response = metadata.prepControlledTermInput(
      controlledTerm,
      formItems
    );
    expect(response).toHaveLength(2);
    expect(response[0].term).toEqual("http://vocab.getty.edu/ulan/500276588");
    expect(response[0].role.id).toEqual("asg");
    expect(response[0].role.scheme).toEqual("MARC_RELATOR");
    expect(response[1].term).toEqual("http://vocab.getty.edu/ulan/500029944");
    expect(response[1].role.id).toEqual("arc");
    expect(response[1].role.scheme).toEqual("MARC_RELATOR");
  });

  it("filters out any fieldset items which contain an undefined term id", () => {
    const response = metadata.prepControlledTermInput(
      {
        hasRole: true,
        label: "Creator",
        name: "creator",
        scheme: "MARC_RELATOR",
      },
      [
        {
          authority: "loc",
          termId: "http://vocab.getty.edu/ulan/500276588",
          label: "Getty Lee",
        },
        {
          authority: "getty",
          termId: "",
          label: "Foot, D. D.",
        },
      ]
    );

    expect(response).toHaveLength(1);
    expect(response).toEqual([
      { term: "http://vocab.getty.edu/ulan/500276588" },
    ]);
  });
});

describe("getCodedTermSelectOptions()", () => {
  const codeListsData = [
    { label: "Ima value", id: "1" },
    { label: "Ima second value", id: "2" },
  ];

  const codedTerm = "LICENSE";

  it("returns an array of values when options exist", () => {
    let expectedValue = [
      {
        label: "Ima value",
        id: '{"id":"1","scheme":"LICENSE","label":"Ima value"}',
      },
      {
        label: "Ima second value",
        id: '{"id":"2","scheme":"LICENSE","label":"Ima second value"}',
      },
    ];
    expect(
      metadata.getCodedTermSelectOptions(codeListsData, codedTerm)
    ).toEqual(expectedValue);
  });

  it("return an empty array if no values exist", () => {
    expect(metadata.getCodedTermSelectOptions()).toEqual([]);
  });
});

describe("prepFieldArrayItemsForPost()", () => {
  var metadataItems = [
    { metadataItem: "Ima value" },
    { metadataItem: "Ima second value" },
  ];

  it("returns an array of string values when items exist", () => {
    let expectedValue = ["Ima value", "Ima second value"];
    expect(metadata.prepFieldArrayItemsForPost(metadataItems)).toEqual(
      expectedValue
    );
  });

  it("return an empty array if no values exist", () => {
    expect(metadata.prepFieldArrayItemsForPost()).toEqual([]);
  });
});

describe("prepNotes()", () => {
  var notesFormValues = [
    {
      note: "note 1",
      typeId: "GENERAL_NOTE",
    },
    {
      note: "note 2",
      typeId: "BIOGRAPHICAL_HISTORICAL_NOTE",
    },
  ];

  it("returns a properly formatted array of notes objects ready for form post", () => {
    let results = metadata.prepNotes(notesFormValues);
    let expectedResults = [
      {
        note: "note 1",
        type: {
          scheme: "NOTE_TYPE",
          id: "GENERAL_NOTE",
        },
      },
      {
        note: "note 2",
        type: {
          scheme: "NOTE_TYPE",
          id: "BIOGRAPHICAL_HISTORICAL_NOTE",
        },
      },
    ];
    expect(results).toEqual(expectedResults);
  });
});

describe("prepRelatedUrl()", () => {
  var relatedUrlFormValues = [
    {
      url: "http://google.com",
      labelId: "HATHI_TRUST_DIGITAL_LIBRARY",
    },
    {
      url: "http://northwestern.edu",
      labelId: "RESEARCH_GUIDE",
    },
  ];

  it("returns a properly formatted array of relatedUrl objects ready for form post", () => {
    let results = metadata.prepRelatedUrl(relatedUrlFormValues);
    let expectedResults = [
      {
        url: "http://google.com",
        label: {
          scheme: "RELATED_URL",
          id: "HATHI_TRUST_DIGITAL_LIBRARY",
        },
      },
      {
        url: "http://northwestern.edu",
        label: {
          scheme: "RELATED_URL",
          id: "RESEARCH_GUIDE",
        },
      },
    ];
    expect(results).toEqual(expectedResults);
  });
});
