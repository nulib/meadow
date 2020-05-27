import * as metadata from "./metadata";

describe("prepControlledTermInput()", () => {
  const controlledTermFormData = [
    {
      id: "http://angelina.net",
      roleId: "aut",
    },
    {
      roleId: "anl",
      id: "http://elroy.info",
      label: "autem occaecati quasi",
    },
  ];

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
    const response = metadata.prepControlledTermInput(controlledTermFormData);
    expect(response).toHaveLength(2);
    expect(response[0].id).toEqual("http://angelina.net");
    expect(response[0].role.id).toEqual("aut");
    expect(response[1].id).toEqual("http://elroy.info");
    expect(response[1].role.id).toEqual("anl");
    expect(response[1].label).toBeUndefined();
  });

  it("preps controlled term form data successfully", () => {
    const response = metadata.prepControlledTermInput(codedTermFormData);
    expect(response).toHaveLength(3);
    expect(response[0].id).toEqual("https://maureen.net");
    expect(response[0].role).toBeUndefined();
    expect(response[1].id).toEqual("https://rylan.info");
    expect(response[2].id).toEqual("https://nu.edu");
  });
});
