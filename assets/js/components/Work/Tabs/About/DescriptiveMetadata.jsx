import React, { useState, useEffect } from "react";
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
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const cacheNotification = css`
  display: flex;
  justify-content: space-between;
  align-items: center;
`;

const WorkTabsAboutDescriptiveMetadata = ({
  control,
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  showDescriptiveMetadata,
}) => {
  const localList = localStorage.getItem("codeLists");
  const [codeLists, setCodeLists] = useState(
    localList ? JSON.parse(localList) : {}
  );
  useEffect(() => {
    localStorage.setItem("codeLists", JSON.stringify(codeLists));
  }, [codeLists]);

  const refreshCache = () => {
    console.log("Refreshing cache :>> ");
    setCodeLists({});
    localStorage.clear();

    // TODO: I think we need to specify 3 more GraphQL queries here, but use "useLazyQuery"
    // and manually fetch the Code List data from the API, then update localStorage similar to
    // how it's currently set up.  Unfortunately the "skip" parameter gets ignored if the current
    // queries change to "useLazyQuery", so we might just have to double up.
  };

  const { data: marcData, loading: marcLoading, errors: marcErrors } = useQuery(
    CODE_LIST_QUERY,
    {
      variables: { scheme: "MARC_RELATOR" },
      skip: codeLists["MARC_RELATOR"] ? true : false,
      onCompleted: (data) => {
        if (!marcErrors && data) {
          setCodeLists({ ...codeLists, ["MARC_RELATOR"]: data.codeList });
        }
      },
    }
  );

  const {
    data: subjectRoleData,
    loading: subjectRoleLoading,
    errors: subjectRoleErrors,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "SUBJECT_ROLE" },
    skip: codeLists["SUBJECT_ROLE"] ? true : false,
    onCompleted: (data) => {
      if (!marcErrors && data) {
        setCodeLists({ ...codeLists, ["SUBJECT_ROLE"]: data.codeList });
      }
    },
  });

  const {
    data: authorityData,
    loading: authorityLoading,
    errors: authorityErrors,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "AUTHORITY" },
    skip: codeLists["AUTHORITY"] ? true : false,
    onCompleted: (data) => {
      if (!marcErrors && data) {
        setCodeLists({ ...codeLists, ["AUTHORITY"]: data.codeList });
      }
    },
  });

  if (marcLoading || authorityLoading || subjectRoleLoading)
    return <UISkeleton rows={20} />;
  if (marcErrors || authorityErrors || subjectRoleErrors)
    return (
      <UIError error={marcErrors || authorityErrors || subjectRoleErrors} />
    );
  if (
    !codeLists.AUTHORITY ||
    !codeLists.MARC_RELATOR ||
    !codeLists.SUBJECT_ROLE
  ) {
    return (
      <UIError
        error={{ message: "No Authority, MARC, or Subject Role data" }}
      />
    );
  }

  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return codeLists.MARC_RELATOR;
    }
    if (scheme === "SUBJECT_ROLE") {
      return codeLists.SUBJECT_ROLE;
    }
    return [];
  }

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
      {isEditing && (
        <div className="notification is-size-7" css={cacheNotification}>
          <p>
            <span className="icon">
              <FontAwesomeIcon icon="bell" />
            </span>
            Role and Authority fields are using cached, dropdown values (as
            these rarely change).
          </p>
          <button
            type="button"
            className="button is-text is-small"
            onClick={refreshCache}
          >
            Sync with latest values
          </button>{" "}
        </div>
      )}
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
