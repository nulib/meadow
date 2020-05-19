import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import { useQuery } from "@apollo/react-hooks";
import { AUTHORITY_SEARCH } from "../../Work/controlledVocabulary.query";
import UIError from "../Error";
import UIInput from "./Input";

const styles = {
  inputWrapper: {
    marginBottom: "1rem",
  },
  deleteButton: {
    marginLeft: "5px",
  },
};

const UIFormControlledTermArray = ({
  codeLists: { authorities = [], marcRelators = [] },
  control,
  errors = {},
  label,
  name,
  register,
  required,
  defaultValue = `New ${label}`,
  ...passedInProps
}) => {
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });

  const [searchVal, setSearchVal] = useState("");
  const [currentAuthority, setCurrentAuthority] = useState(authorities[0].id);

  const {
    data: searchData,
    loading: searchLoading,
    errors: searchErrors,
    refetch: searchRefetch,
    networkStatus: searchNetWorkStatus,
  } = useQuery(AUTHORITY_SEARCH, {
    variables: {
      authority: { id: currentAuthority, scheme: "AUTHORITY" },
      query: searchVal,
    },
    notifyOnNetworkStatusChange: true,
  });

  const handleAuthorityChange = (e) => {
    console.log("e.target.value :>> ", e.target.value);
    setCurrentAuthority(e.target.value);
  };

  const handleInputChange = (e) => {
    setSearchVal(e.target.value);
    searchRefetch();
  };

  if (searchNetWorkStatus === 4) return "Refetching authority search query";
  if (searchErrors) return <UIError error={searchErrors} />;

  return (
    <div className="">
      <ul style={styles.inputWrapper}>
        {fields.map((item, index) => {
          return (
            <li key={item.id} className="">
              <fieldset {...passedInProps}>
                <legend data-testid="legend">{`${label} #${index + 1}`}</legend>
                <div className="field">
                  <label className="label">Role</label>
                  <UIFormSelect
                    name={`${[name]}-role[${index}]`}
                    label="Role"
                    options={marcRelators}
                    register={register}
                  />
                </div>
                <div className="field">
                  <label className="label">Authority</label>
                  <UIFormSelect
                    name={`${[name]}-authority[${index}]`}
                    label="Authority"
                    options={authorities}
                    register={register}
                    onChange={handleAuthorityChange}
                  />
                </div>
                <div className="field">
                  <label className="label">{label}</label>
                  <UIInput
                    name={`${[name]}[${index}]`}
                    label={label}
                    register={register}
                    onChange={handleInputChange}
                    required
                  />
                </div>
                {errors[name] && errors[name][index] && (
                  <p data-testid="input-errors" className="help is-danger">
                    {label || name} field is required
                  </p>
                )}
                <button
                  type="button"
                  className="button is-fullwidth is-light"
                  onClick={() => remove(index)}
                  style={styles.deleteButton}
                  data-testid="button-delete-field-array-row"
                >
                  <FontAwesomeIcon icon="trash" />
                </button>
              </fieldset>
            </li>
          );
        })}
      </ul>

      <button
        type="button"
        className="button is-text is-small"
        onClick={() => {
          append(defaultValue);
        }}
        data-testid="button-add-field-array-row"
      >
        <span className="icon">
          <FontAwesomeIcon icon="plus" />
        </span>
        <span>Add {fields.length > 0 && "another"}</span>
      </button>
    </div>
  );
};

UIFormControlledTermArray.propTypes = {
  codeLists: PropTypes.shape({
    authorities: PropTypes.array,
    marcRelators: PropTypes.array,
  }),
  control: PropTypes.object.isRequired,
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  register: PropTypes.func,
  required: PropTypes.bool,
};

export default UIFormControlledTermArray;
