import * as metadata from "./metadata";

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
