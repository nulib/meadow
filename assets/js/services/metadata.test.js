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

  // const controlledTermFormData = [
  //   {
  //     termId: "http://angelina.net",
  //     roleId: "aut",
  //   },
  //   {
  //     roleId: "anl",
  //     termId: "http://elroy.info",
  //     label: "autem occaecati quasi",
  //   },
  // ];

  const codedTermFormData = [
    {
      id: "https://maureen.net",
    },
    {
      id: "https://rylan.info",
      label: "aut provident magnam",
    },
    {
      id: "https://nu.edu",
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

  // it("preps controlled term form data successfully", () => {
  //   const response = metadata.prepControlledTermInput(codedTermFormData);
  //   expect(response).toHaveLength(3);
  //   expect(response[0].term).toEqual("https://maureen.net");
  //   expect(response[0].role).toBeUndefined();
  //   expect(response[1].term).toEqual("https://rylan.info");
  //   expect(response[2].term).toEqual("https://nu.edu");
  // });
});
