import React, { useRef, useState, useEffect } from "react";
import PropTypes from "prop-types";
import { useLazyQuery } from "@apollo/client";
import UIControlledTermList from "../../../UI/ControlledTerm/List";
import UIFormField from "../../../UI/Form/Field";
import UIError from "../../../UI/Error";
import UIFormControlledTermArray from "../../../UI/Form/ControlledTermArray";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.gql.js";
import { CONTROLLED_METADATA } from "../../../../services/metadata";
import UISkeleton from "../../../UI/Skeleton";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const cacheNotification = css`
  display: flex;
  justify-content: space-between;
  align-items: center;
`;

const WorkTabsAboutControlledMetadata = ({
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  control,
}) => {
  const firstLaunch = useRef(true);
  const [codeLists, setCodeLists] = useState(
    localStorage.getItem("codeLists")
      ? JSON.parse(localStorage.getItem("codeLists"))
      : {}
  );

  useEffect(() => {
    if (firstLaunch.current) {
      firstLaunch.current = false;
      return;
    }
    console.log("Setting localstorage with ", codeLists);
    localStorage.setItem("codeLists", JSON.stringify(codeLists));
  }, [codeLists]);

  const [
    getMarcData,
    { data: marcData, loading: marcLoading, errors: marcErrors },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      if (!marcErrors && data) {
        setCodeLists({ ...codeLists, ["MARC_RELATOR"]: data.codeList });
      }
    },
  });

  const [
    getSubjectRoleData,
    {
      data: subjectRoleData,
      loading: subjectRoleLoading,
      errors: subjectRoleErrors,
    },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      if (!subjectRoleErrors && data) {
        setCodeLists({ ...codeLists, ["SUBJECT_ROLE"]: data.codeList });
      }
    },
  });

  const [
    getAuthorityData,
    { data: authorityData, loading: authorityLoading, errors: authorityErrors },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      if (!authorityErrors && data) {
        console.log("Here with new data ", data);
        setCodeLists({ ...codeLists, ["AUTHORITY"]: data.codeList });
      }
    },
  });

  useEffect(() => {
    if (!codeLists || !codeLists.MARC_RELATOR) {
      getMarcData({
        variables: { scheme: "MARC_RELATOR" },
      });
    }

    if (!codeLists || !codeLists.SUBJECT_ROLE) {
      getSubjectRoleData({
        variables: { scheme: "SUBJECT_ROLE" },
      });
    }

    if (!codeLists || !codeLists.AUTHORITY) {
      getAuthorityData({
        variables: { scheme: "AUTHORITY" },
      });
    }
  }, []);

  const refreshCache = () => {
    setCodeLists({});
    localStorage.clear();
    getMarcData({
      variables: { scheme: "MARC_RELATOR" },
    });
    getSubjectRoleData({
      variables: { scheme: "SUBJECT_ROLE" },
    });
    getAuthorityData({
      variables: { scheme: "AUTHORITY" },
    });
  };

  if (marcLoading || authorityLoading || subjectRoleLoading)
    return <UISkeleton rows={20} />;
  if (marcErrors || authorityErrors || subjectRoleErrors)
    return (
      <UIError error={marcErrors || authorityErrors || subjectRoleErrors} />
    );

  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return codeLists.MARC_RELATOR;
    }
    if (scheme === "SUBJECT_ROLE") {
      return codeLists.SUBJECT_ROLE;
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
      {isEditing && (
        <div className="notification is-size-7" css={cacheNotification}>
          <p>
            <span className="icon">
              <FontAwesomeIcon icon="bell" />
            </span>
            Role and Authority fields are using cached dropdown values (as these
            rarely change).
          </p>
          <button
            type="button"
            className="button is-text is-small"
            onClick={refreshCache}
          >
            Sync with latest values
          </button>
        </div>
      )}
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
