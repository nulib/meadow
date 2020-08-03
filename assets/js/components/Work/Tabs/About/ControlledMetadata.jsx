import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import UIControlledTermList from "../../../UI/ControlledTerm/List";
import UIFormField from "../../../UI/Form/Field";
import UIFormControlledTermArray from "../../../UI/Form/ControlledTermArray";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.gql.js";
import { CONTROLLED_METADATA } from "../../../../services/metadata";
import UISkeleton from "../../../UI/Skeleton";

const WorkTabsAboutControlledMetadata = ({
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  control,
}) => {
  const {
    data: marcData,
    loading: marcLoading,
    errors: marcErrors,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "MARC_RELATOR" } });
  const {
    data: subjectRoleData,
    loading: subjectRoleLoading,
    errors: subjectRoleErrors,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "SUBJECT_ROLE" } });
  const {
    data: authorityData,
    loading: authorityLoading,
    errors: authorityErrors,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "AUTHORITY" } });

  if (marcLoading || authorityLoading || subjectRoleLoading)
    return <UISkeleton rows={20} />;
  if (marcErrors || authorityErrors || subjectRoleErrors)
    return (
      <div {...restProps}>
        <UIError error={marcErrors || authorityErrors || subjectRoleErrors} />
      </div>
    );
  if (!authorityData || !marcData || !subjectRoleData) {
    return (
      <div {...restProps}>
        <UIError
          error={{ message: "No Authority, MARC, or Subject Role data" }}
        />
      </div>
    );
  }

  const codeLists = {
    AUTHORITY: authorityData.codeList,
    MARC_RELATOR: marcData.codeList,
    SUBJECT_ROLE: subjectRoleData.codeList,
  };
  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return marcData.codeList;
    }
    if (scheme === "SUBJECT_ROLE") {
      return subjectRoleData.codeList;
    }
    return [];
  }

  return (
    <div data-testid="controlled-metadata">
      <ul>
        {CONTROLLED_METADATA.map(({ label, name, scheme }) => (
          <li key={name} className="mb-5">
            <UIFormField label={label}>
              {isEditing ? (
                <UIFormControlledTermArray
                  authorities={codeLists.AUTHORITY}
                  roleDropdownOptions={getRoleDropDownOptions(scheme)}
                  control={control}
                  errors={errors}
                  label={label}
                  name={name}
                  register={register}
                />
              ) : (
                <UIControlledTermList items={descriptiveMetadata[name]} />
              )}
            </UIFormField>
          </li>
        ))}
      </ul>
    </div>
  );
};

WorkTabsAboutControlledMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  register: PropTypes.func,
  control: PropTypes.object,
};

export default WorkTabsAboutControlledMetadata;
