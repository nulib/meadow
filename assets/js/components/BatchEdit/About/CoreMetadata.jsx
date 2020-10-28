import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import UIInput from "../../UI/Form/Input";
import UIFormTextarea from "../../UI/Form/Textarea";
import UIFormField from "../../UI/Form/Field";
import UIFormBatchFieldArray from "../../UI/Form/BatchFieldArray";
import UIFormSelect from "../../UI/Form/Select";
import { GET_COLLECTIONS } from "@js/components/Collection/collection.gql";
import { useFormContext } from "react-hook-form";
import { useCodeLists } from "@js/context/code-list-context";

const BatchEditAboutCoreMetadata = ({ ...restProps }) => {
  const codeLists = useCodeLists();

  const {
    loading: collectionLoading,
    error: collectionError,
    data: collectionData,
  } = useQuery(GET_COLLECTIONS);

  const context = useFormContext();
  const register = context.register;

  return (
    <div
      className="columns is-multiline"
      data-testid="core-metadata"
      {...restProps}
    >
      <div className="column is-full">
        {/* Title */}
        <UIFormField label="Title">
          <UIInput
            isReactHookForm
            name="title"
            label="Title"
            data-testid="title"
          />
        </UIFormField>
      </div>

      <div className="column is-full">
        {/* Alternate Title */}
        <UIFormBatchFieldArray
          name="alternateTitle"
          data-testid="alternate-title"
          label="Alternate Title"
        />
      </div>
      <div className="column is-full">
        <UIFormField label="Collection">
          <div className="select">
            <select name="collection" ref={register()} data-testid="collection">
              <option value="">-- Select --</option>
              {collectionData &&
                collectionData.collections.map((collection) => (
                  <option
                    key={collection.id}
                    value={JSON.stringify(collection)}
                  >
                    {collection.title}
                  </option>
                ))}
            </select>
          </div>
        </UIFormField>
      </div>
      <div className="column is-half">
        {/* Date Created */}
        <UIFormField label="Date Created" notLive>
          <UIInput
            isReactHookForm
            name="dateCreated"
            label="Date Created"
            type="date"
            data-testid="date-created"
          />
          <UITagNotYetSupported label="Display not yet supported" />
          <UITagNotYetSupported label="Update not yet supported" />
        </UIFormField>
      </div>
      <div className="column is-half">
        <UIFormField label="Rights Statement">
          <UIFormSelect
            isReactHookForm
            name="rightsStatement"
            label="Rights Statement"
            options={
              codeLists.rightsStatementData
                ? codeLists.rightsStatementData.codeList
                : []
            }
            data-testid="rights-statement"
            showHelper
          />
        </UIFormField>
      </div>
      <div className="column is-full">
        {/* Description */}
        <UIFormField label="Description">
          <UIFormTextarea
            isReactHookForm
            name="description"
            label="Description"
            data-testid="description"
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutCoreMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutCoreMetadata;
