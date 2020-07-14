import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../../UI/Form/Field";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIControlledTermList from "../../../UI/ControlledTerm/List";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.gql.js";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import UIFormControlledTermArray from "../../../UI/Form/ControlledTermArray";
import { useQuery } from "@apollo/react-hooks";
import UIError from "../../../UI/Error";
import { DESCRIPTIVE_METADATA } from "../../../../services/metadata";
import UISkeleton from "../../../UI/Skeleton";

const WorkTabsAboutDescriptiveMetadata = ({
  control,
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  showDescriptiveMetadata,
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
      <UIError error={marcErrors || authorityErrors || subjectRoleErrors} />
    );
  if (!authorityData || !marcData || !subjectRoleData) {
    return (
      <UIError
        error={{ message: "No Authority, MARC, or Subject Role data" }}
      />
    );
  }

  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return marcData.codeList;
    }
    if (scheme === "SUBJECT_ROLE") {
      return subjectRoleData.codeList;
    }
    return [];
  }

  // const codeLists = {
  //   authorities: authorityData.codeList,
  //   marcRelators: marcData.codeList,
  //   subjectRole: subjectRoleData.codeList
  // };

  return showDescriptiveMetadata ? (
    <div>
      <h3 className="subtitle is-size-5 is-marginless pb-4">Field Arrays</h3>
      <div className="columns is-multiline">
        {DESCRIPTIVE_METADATA.fieldArrays.map((item) => (
          <div key={item.name} className="column is-half">
            {isEditing ? (
              <UIFormFieldArray
                register={register}
                control={control}
                required
                name={item.name}
                label={item.label}
                errors={errors}
              />
            ) : (
              <UIFormFieldArrayDisplay
                items={descriptiveMetadata[item.name]}
                label={item.label}
              />
            )}
          </div>
        ))}
      </div>

      <hr />
      <h3 className="subtitle is-size-5 ">Controlled Terms</h3>
      <ul>
        {DESCRIPTIVE_METADATA.controlledTerms.map(({ label, name, scheme }) => (
          <li key={name} className="mb-5">
            <UIFormField label={label}>
              {isEditing ? (
                <UIFormControlledTermArray
                  authorities={authorityData.codeList}
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
  ) : null;
};

WorkTabsAboutDescriptiveMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  descriptiveMetadata: PropTypes.object.isRequired,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  register: PropTypes.func.isRequired,
  showDescriptiveMetadata: PropTypes.bool,
};

export default WorkTabsAboutDescriptiveMetadata;
