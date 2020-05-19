import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/react-hooks";
import UITagNotYetSupported from "../../../UI/TagNotYetSupported";
import UIInput from "../../../UI/Form/Input";
import UIFormTextarea from "../../../UI/Form/Textarea";
import UIFormField from "../../../UI/Form/Field";
import UIFormSelect from "../../../UI/Form/Select";
import UICodedTermItem from "../../../UI/CodedTerm/Item";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.query.js";

const WorkTabsAboutCoreMetadata = ({
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  showCoreMetadata,
}) => {
  const {
    loading: rightsStatementsLoading,
    error: rightsStatementsError,
    data: rightsStatementsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "RIGHTS_STATEMENT" },
  });

  return showCoreMetadata ? (
    <div className="columns is-multiline">
      <div className="column is-half">
        {/* Title */}
        <UIFormField label="Title">
          {isEditing ? (
            <UIInput
              register={register}
              required
              name="title"
              label="Title"
              data-testid="title"
              errors={errors}
              defaultValue={descriptiveMetadata.title}
            />
          ) : (
            <p>{descriptiveMetadata.title || "No value"}</p>
          )}
        </UIFormField>
      </div>
      <div className="column is-half">
        {/* Description */}
        <UIFormField label="Description">
          {isEditing ? (
            <UIFormTextarea
              register={register}
              required
              name="description"
              label="Description"
              data-testid="description"
              errors={errors}
              defaultValue={descriptiveMetadata.description}
            />
          ) : (
            <p>{descriptiveMetadata.description || "No value"}</p>
          )}
        </UIFormField>
      </div>

      <div className="column is-half">
        <UIFormField label="Rights Statement" notLive mocked>
          {isEditing ? (
            <UIFormSelect
              register={register}
              name="rightsStatement"
              label="Rights Statement"
              options={
                rightsStatementsData ? rightsStatementsData.codeList : []
              }
              defaultValue={descriptiveMetadata.rightsStatement.id}
              errors={errors}
            />
          ) : (
            <UICodedTermItem item={descriptiveMetadata.rightsStatement} />
          )}
        </UIFormField>
      </div>
      <div className="column is-half">
        {/* Date Created */}
        <UIFormField label="Date Created" isEditing={isEditing}>
          {isEditing ? (
            <UIInput
              register={register}
              name="dateCreated"
              label="Date Created"
              type="date"
              data-testid="date-created"
              errors={errors}
              defaultValue={descriptiveMetadata.dateCreated}
            />
          ) : (
            <>
              <UITagNotYetSupported label="Display not yet supported" />
              <UITagNotYetSupported label="Update not yet supported" />
            </>
          )}
        </UIFormField>
      </div>
    </div>
  ) : null;
};

WorkTabsAboutCoreMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  register: PropTypes.func,
  showCoreMetadata: PropTypes.bool,
};

export default WorkTabsAboutCoreMetadata;
