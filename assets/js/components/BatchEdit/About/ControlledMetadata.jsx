import React, { useRef, useState, useEffect } from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";
import UIFormControlledTermArray from "../../UI/Form/ControlledTermArray";
import { useLazyQuery } from "@apollo/client";
import UIError from "../../UI/Error";
import { CONTROLLED_METADATA } from "../../../services/metadata";
import UISkeleton from "../../UI/Skeleton";
import BatchEditRemove from "../Remove";
import BatchEditModalRemove from "../ModalRemove";
import { useBatchState } from "../../../context/batch-edit-context";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const cacheNotification = css`
  display: flex;
  justify-content: space-between;
  align-items: center;
`;

const BatchEditAboutControlledMetadata = ({
  control,
  errors,
  register,
  ...restProps
}) => {
  // This holds all the ElasticSearch Search info
  const batchState = useBatchState();
  const aggregations = batchState.parsedAggregations;

  const [isRemoveModalOpen, setIsRemoveModalOpen] = useState();
  const [currentRemoveField, setCurrentRemoveField] = useState();

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
    localStorage.setItem("codeLists", JSON.stringify(codeLists));
  }, [codeLists]);

  const [
    getMarcData,
    { data: marcData, loading: marcLoading, errors: marcErrors },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      console.log("Getting marcData");
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

  function handleRemoveButtonClick(fieldObj) {
    console.log("fieldObj", fieldObj);
    setCurrentRemoveField(fieldObj);
    setIsRemoveModalOpen(true);
  }

  function handleCloseRemoveModalClick() {
    setIsRemoveModalOpen(false);
  }

  return (
    <div data-testid="controlled-metadata" {...restProps}>
      <ul>
        {CONTROLLED_METADATA.map(({ label, name, scheme }) => (
          <li key={name} className="mb-5" data-testid={name}>
            <UIFormField label={label}>
              <UIFormControlledTermArray
                authorities={codeLists.AUTHORITY}
                roleDropdownOptions={getRoleDropDownOptions(scheme)}
                control={control}
                errors={errors}
                label={label}
                name={name}
                register={register}
              />
            </UIFormField>
            <BatchEditRemove
              handleRemoveClick={handleRemoveButtonClick}
              label={label}
              name={name}
              removeItems={
                (batchState.removeItems && batchState.removeItems[name]) || []
              }
            />
          </li>
        ))}
      </ul>

      <BatchEditModalRemove
        closeModal={handleCloseRemoveModalClick}
        currentRemoveField={currentRemoveField}
        items={
          aggregations && currentRemoveField
            ? aggregations[currentRemoveField.name]
            : []
        }
        isRemoveModalOpen={isRemoveModalOpen}
      />

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
