import React, { useRef, useState, useEffect } from "react";
import PropTypes from "prop-types";
import UIControlledTermList from "../../../UI/ControlledTerm/List";
import UIFormField from "../../../UI/Form/Field";
import UIError from "../../../UI/Error";
import UIFormControlledTermArray from "../../../UI/Form/ControlledTermArray";
import { CONTROLLED_METADATA } from "../../../../services/metadata";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import useCachedCodeLists from "../../../../hooks/useCachedCodeLists";

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
  const [codeLists, refreshCodeLists] = useCachedCodeLists();

  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return codeLists.MARC_RELATOR;
    }
    if (scheme === "SUBJECT_ROLE") {
      return codeLists.SUBJECT_ROLE;
    }
    return [];
  }

  // Still updating, so return a null
  if (!codeLists) {
    return null;
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
            onClick={() => refreshCodeLists()}
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
