import React, { useState } from "react";
import PropTypes from "prop-types";
import { useCombobox } from "downshift";
import { useFieldArray, useFormContext } from "react-hook-form";
import { useLazyQuery } from "@apollo/client";
import { AUTHORITIES_SEARCH, GEONAMES_PLACE } from "../../controlledVocabulary.gql";
import UIFormField from "../../../UI/Form/Field";
import { IconAdd, IconTrashCan } from "@js/components/Icon";
import { Button } from "@nulib/design-system";

const WorkTabsAboutGeoNamesNavPlace = ({ descriptiveMetadata, isEditing }) => {
  const { control } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name: "navPlace",
    keyName: "useFieldArrayId",
  });

  const navPlaceFeatures = descriptiveMetadata?.navPlace?.features || [];

  const handleAddAnother = () => {
    append({
      termId: "",
      label: "",
      summary: "",
      latitude: "",
      longitude: "",
    });
  };

  return (
    <div data-testid="geonames-nav-place">
      {isEditing ? (
        <>
          <ul className="mb-3">
            {fields.map((item, index) => (
              <li key={item.useFieldArrayId}>
                <GeoNamesNavPlaceItem item={item} index={index} remove={remove} />
              </li>
            ))}
          </ul>
          <Button isLight onClick={handleAddAnother}>
            <IconAdd />
            <span>Add {fields.length > 0 && "another"}</span>
          </Button>
        </>
      ) : (
        <GeoNamesNavPlaceList features={navPlaceFeatures} />
      )}
    </div>
  );
};

const GeoNamesNavPlaceItem = ({ index, item, remove }) => {
  const {
    formState: { errors },
    register,
    setValue,
  } = useFormContext();

  const inputName = `navPlace[${index}]`;
  const hasErrors = errors.navPlace && errors.navPlace[index]?.label;
  const [isLoading, setIsLoading] = useState(false);
  const isExistingEntry = Boolean(item.termId && item.label);

  const [searchGeoNames, { data: searchData }] = useLazyQuery(
    AUTHORITIES_SEARCH,
    {
      onCompleted: () => setIsLoading(false),
    }
  );

  const [fetchGeoNamesPlace] = useLazyQuery(GEONAMES_PLACE, {
    onCompleted: (data) => {
      setIsLoading(false);
      const feature = data?.geonamesPlace;
      const coordinates = feature?.geometry?.coordinates || [];
      if (coordinates.length >= 2) {
        setValue(`${inputName}.longitude`, coordinates[0]);
        setValue(`${inputName}.latitude`, coordinates[1]);
      }
      const summary = feature?.properties?.summary?.en?.[0];
      if (summary) {
        setValue(`${inputName}.summary`, summary);
      }
    },
    onError: () => setIsLoading(false),
  });

  const handleInputChange = (value) => {
    if (!value) return;
    setIsLoading(true);
    setValue(`${inputName}.termId`, "");
    setValue(`${inputName}.latitude`, "");
    setValue(`${inputName}.longitude`, "");
    setValue(`${inputName}.summary`, "");
    searchGeoNames({
      variables: {
        authority: "geonames",
        query: value,
      },
    });
  };

  const handleItemSelected = (selectedItem) => {
    if (!selectedItem) return;
    setIsLoading(true);
    setValue(`${inputName}.termId`, selectedItem.id);
    setValue(`${inputName}.label`, selectedItem.label);
    setValue(`${inputName}.summary`, selectedItem.hint || "");
    fetchGeoNamesPlace({ variables: { id: selectedItem.id } });
  };

  return (
    <fieldset className="mb-5">
      <legend className="has-text-grey has-text-weight-light">{`Place #${
        index + 1
      }`}</legend>

      <input
        type="hidden"
        {...register(`${inputName}.termId`)}
        defaultValue={item.termId}
      />
      <input
        type="hidden"
        {...register(`${inputName}.summary`)}
        defaultValue={item.summary}
      />
      <input
        type="hidden"
        {...register(`${inputName}.latitude`)}
        defaultValue={item.latitude}
      />
      <input
        type="hidden"
        {...register(`${inputName}.longitude`)}
        defaultValue={item.longitude}
      />

      {isExistingEntry ? (
        <p>
          {item.label}
          <br />
          {item.termId}
          {item.summary ? (
            <>
              <br />
              {item.summary}
            </>
          ) : null}
          {item.latitude && item.longitude ? (
            <>
              <br />
              Coordinates: {item.latitude}, {item.longitude}
            </>
          ) : null}
        </p>
      ) : (
        <>
          <GeoNamesComboBox
            data={searchData}
            handleInputChange={handleInputChange}
            handleItemSelected={handleItemSelected}
            hasErrors={hasErrors}
            inputName={inputName}
            initialInputValue={item.label || ""}
            isLoading={isLoading}
          />

          {item.latitude && item.longitude && (
            <p className="help">
              Coordinates: {item.latitude}, {item.longitude}
            </p>
          )}

          {hasErrors && (
            <p data-testid="input-errors" className="help is-danger">
              Location field is required
            </p>
          )}
        </>
      )}

      {isExistingEntry && (
        <input
          type="hidden"
          {...register(`${inputName}.label`)}
          defaultValue={item.label}
        />
      )}

      <button
        type="button"
        className="button is-light is-small mt-3"
        onClick={() => remove(index)}
      >
        <span className="icon">
          <IconTrashCan />
        </span>
        <span>Remove</span>
      </button>
    </fieldset>
  );
};

const GeoNamesComboBox = ({
  data: { authoritiesSearch = [], loading } = {},
  handleInputChange,
  handleItemSelected,
  hasErrors,
  inputName,
  initialInputValue,
  isLoading,
}) => {
  const { register } = useFormContext();

  const stateReducer = (state, actionAndChanges) => {
    const { type, changes } = actionAndChanges;
    switch (type) {
      case useCombobox.stateChangeTypes.InputBlur:
        return {
          ...changes,
          ...((typeof changes.inputValue === "string" ||
            !changes.selectedItem) && {
            inputValue: "",
          }),
        };
      default:
        return changes;
    }
  };

  const {
    getInputProps,
    getItemProps,
    getMenuProps,
    highlightedIndex,
    isOpen,
  } = useCombobox({
    initialInputValue,
    stateReducer,
    items: authoritiesSearch,
    itemToString: (item) => (item ? item.label : ""),
    onInputValueChange: ({ inputValue, type }) => {
      if (type === useCombobox.stateChangeTypes.InputChange) {
        handleInputChange(inputValue);
      }
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
      <UIFormField label="GeoNames place">
        <input
          {...getInputProps({
            className: `input ${hasErrors ? "is-danger" : ""}`,
            name: `${inputName}.label`,
            ...register(`${inputName}.label`, { required: true }),
          })}
        />
      </UIFormField>

      {isLoading && <div className="loader mt-4"></div>}

      <ul {...getMenuProps()}>
        {isOpen &&
          authoritiesSearch.map((item, index) => (
            <li
              className="py-3 px-3"
              style={
                highlightedIndex === index
                  ? { backgroundColor: "whitesmoke" }
                  : {}
              }
              key={`${item.id}-${index}`}
              {...getItemProps({ item, index })}
            >
              <strong>{item.label}</strong>
              {item.hint ? ` • ${item.hint}` : ""}
            </li>
          ))}
      </ul>
    </>
  );
};

const GeoNamesNavPlaceList = ({ features }) => {
  if (!features.length) {
    return <p className="has-text-grey">No locations added.</p>;
  }

  return (
    <ul>
      {features.map((feature, index) => {
        const label =
          feature?.properties?.label?.en?.[0] || feature?.properties?.label?.none?.[0];
        const summary = feature?.properties?.summary?.en?.[0];
        const coordinates = feature?.geometry?.coordinates || [];
        return (
          <li key={`${feature.id || "feature"}-${index}`}>
            <strong>{label || "Unknown place"}</strong>
            {summary ? ` • ${summary}` : ""}
            {coordinates.length >= 2
              ? ` (${coordinates[1]}, ${coordinates[0]})`
              : ""}
          </li>
        );
      })}
    </ul>
  );
};

WorkTabsAboutGeoNamesNavPlace.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
};

GeoNamesNavPlaceItem.propTypes = {
  index: PropTypes.number.isRequired,
  item: PropTypes.object.isRequired,
  remove: PropTypes.func.isRequired,
};

GeoNamesComboBox.propTypes = {
  data: PropTypes.object,
  handleInputChange: PropTypes.func.isRequired,
  handleItemSelected: PropTypes.func.isRequired,
  hasErrors: PropTypes.bool,
  inputName: PropTypes.string.isRequired,
  initialInputValue: PropTypes.string,
  isLoading: PropTypes.bool,
};

GeoNamesNavPlaceList.propTypes = {
  features: PropTypes.array,
};

export default WorkTabsAboutGeoNamesNavPlace;
