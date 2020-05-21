import React, { useState, useEffect } from "react";
import { useLazyQuery } from "@apollo/react-hooks";
import { AUTHORITY_SEARCH } from "../../Work/controlledVocabulary.query";
import UIError from "../Error";
import UIFormSelect from "./Select";
import UIFormInput from "./Input";
import { useCombobox } from "downshift";

const UIFormControlledTermArrayItem = ({
  authorities,
  control,
  errors,
  index,
  item,
  label,
  name,
  register,
}) => {
  const [currentAuthority, setCurrentAuthority] = useState(authorities[0].id);
  const [getAuthResults, { loading, data }] = useLazyQuery(AUTHORITY_SEARCH);
  const inputName = `${[name]}[${index}]`;
  const hasErrors = errors[name] && errors[name][index];

  const handleAuthorityChange = (e) => {
    setCurrentAuthority(e.target.value);
  };

  const handleInputChange = (val) => {
    getAuthResults({
      variables: {
        authority: {
          id: currentAuthority,
          scheme: "AUTHORITY",
        },
        query: val,
      },
    });
  };

  const handleItemSelected = (val) => {
    control.setValue([{ [`${inputName}.id`]: val.id }]);
  };

  return (
    <>
      <div className="field">
        <label className="label">Authority</label>
        <UIFormSelect
          name={`${[name]}Authority[${index}]`}
          label="Authority"
          options={authorities}
          onChange={handleAuthorityChange}
        />
      </div>

      {/* Hidden form field which tracks the "id" of selection, which we need in form submit */}
      <input type="hidden" name={`${inputName}.id`} ref={register()} />

      <div className="field">
        <DropDownComboBox
          data={data}
          handleInputChange={handleInputChange}
          handleItemSelected={handleItemSelected}
          hasErrors={hasErrors}
          inputName={inputName}
          register={register}
        />
        {hasErrors && (
          <p data-testid="input-errors" className="help is-danger">
            {label || name} field is required
          </p>
        )}
      </div>
    </>
  );
};

function DropDownComboBox({
  data: { authoritiesSearch = [], loading } = {},
  handleInputChange,
  handleItemSelected,
  hasErrors,
  inputName,
  register,
}) {
  const {
    getLabelProps,
    getMenuProps,
    getInputProps,
    getComboboxProps,
    getItemProps,
    highlightedIndex,
    isOpen,
    selectedItem,
  } = useCombobox({
    items: authoritiesSearch,
    itemToString: (item) => (item ? item.label : ""),
    onInputValueChange: ({ inputValue }) => {
      handleInputChange(inputValue);
    },
    onSelectedItemChange: ({ selectedItem }) => {
      handleItemSelected(selectedItem);
    },
  });

  if (loading) {
    return <p>...Loading</p>;
  }

  return (
    <>
      <label {...getLabelProps({ className: "label" })}>Choose an item:</label>
      <div {...getComboboxProps()}>
        <input
          {...getInputProps({
            className: `input ${hasErrors ? "is-danger" : ""}`,
            name: `${inputName}.label`,
            ref: register({ required: true }),
          })}
        />
      </div>
      <ul {...getMenuProps()}>
        {isOpen &&
          authoritiesSearch.map((item, index) => (
            <li
              style={
                highlightedIndex === index
                  ? { backgroundColor: "whitesmoke" }
                  : {}
              }
              key={`${item}${index}`}
              {...getItemProps({ item, index })}
            >
              {item.label}
            </li>
          ))}
      </ul>
    </>
  );
}

export default UIFormControlledTermArrayItem;
