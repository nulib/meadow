import React from "react";
import { render, fireEvent } from "@testing-library/react";
import UIFormRelatedURL from "./RelatedURL";
import { useForm } from "react-hook-form";
import { relatedUrlSchemeMock } from "../../Work/controlledVocabulary.gql.mock";

const props = {
  codeLists: relatedUrlSchemeMock,
  name: "relatedUrl",
  label: "Related URL",
  errors: {},
};

const withReactHookFormControl = (WrappedComponent) => {
  const HOC = () => {
    const { control, register } = useForm({
      defaultValues: {},
    });

    return (
      <WrappedComponent {...props} control={control} register={register} />
    );
  };

  return HOC;
};

describe("InputMultiple component", () => {
  function setUpTests() {
    const Wrapped = withReactHookFormControl(UIFormRelatedURL);
    return render(<Wrapped {...props} />);
  }

  it("renders without crashing", () => {
    expect(setUpTests());
  });

  it("renders Add button and creates new related URL on click", () => {
    const { getByTestId } = setUpTests();
    const addButton = getByTestId("button-add-field-array-row");
    expect(addButton).toBeInTheDocument();
    fireEvent.click(addButton);
    fireEvent.click(addButton);

    expect(getByTestId("relatedURL-item-0")).toBeInTheDocument();
    expect(getByTestId("relatedURL-input-url-0")).toBeInTheDocument();
    expect(getByTestId("relatedURL-input-select-0")).toBeInTheDocument();
    expect(getByTestId("relatedURL-item-1")).toBeInTheDocument();
    expect(getByTestId("relatedURL-input-url-1")).toBeInTheDocument();
    expect(getByTestId("relatedURL-input-select-1")).toBeInTheDocument();
  });

  it("renders delete button, removes related URL on click", () => {
    const { getByTestId, queryByTestId } = setUpTests();
    const addButton = getByTestId("button-add-field-array-row");
    expect(addButton).toBeInTheDocument();
    fireEvent.click(addButton);
    fireEvent.click(addButton);
    fireEvent.click(addButton);
    expect(getByTestId("relatedURL-item-0")).toBeInTheDocument();
    expect(getByTestId("relatedURL-item-1")).toBeInTheDocument();
    expect(getByTestId("relatedURL-item-2")).toBeInTheDocument();

    const deleteButton0 = getByTestId("button-delete-field-array-row-0");
    const deleteButton1 = getByTestId("button-delete-field-array-row-1");
    const deleteButton2 = getByTestId("button-delete-field-array-row-2");
    expect(deleteButton0).toBeInTheDocument();
    expect(deleteButton1).toBeInTheDocument();
    expect(deleteButton2).toBeInTheDocument();

    fireEvent.click(deleteButton1);
    fireEvent.click(deleteButton2);
    expect(queryByTestId("relatedURL-item-1")).not.toBeInTheDocument();
    expect(queryByTestId("relatedURL-item-2")).not.toBeInTheDocument();
  });
});
