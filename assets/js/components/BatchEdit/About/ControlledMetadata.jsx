import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";
import UIFormControlledTermArray from "../../UI/Form/ControlledTermArray";
import { useQuery } from "@apollo/client";
import UIError from "../../UI/Error";
import { CONTROLLED_METADATA } from "../../../services/metadata";
import UISkeleton from "../../UI/Skeleton";

const BatchEditAboutControlledMetadata = ({
  control,
  errors,
  register,
  ...restProps
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
    <div data-testid="controlled-metadata" {...restProps}>
      <ul>
        {CONTROLLED_METADATA.map(({ label, name, scheme }) => (
          <li key={name} className="mb-5" data-testid={name}>
            <UIFormField label={label}>
              <UIFormControlledTermArray
                authorities={authorityData.codeList}
                roleDropdownOptions={getRoleDropDownOptions(scheme)}
                control={control}
                errors={errors}
                label={label}
                name={name}
                register={register}
              />
            </UIFormField>
          </li>
        ))}
      </ul>
    </div>
  );
};

BatchEditAboutControlledMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  errors: PropTypes.object,
  register: PropTypes.func.isRequired,
  restProps: PropTypes.object,
};

export default BatchEditAboutControlledMetadata;
