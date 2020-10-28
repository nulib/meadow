import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormInput from "../../UI/Form/Input";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql";
import { useQuery, useMutation } from "@apollo/client";
import { useFormContext } from "react-hook-form";

const BatchEditAdministrativeProjectStatusMetadata = ({ ...restProps }) => {
  const context = useFormContext();
  const register = context.register;
  const {
    loading: libraryUnitLoading,
    error: libraryUnitError,
    data: libraryUnitData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "LIBRARY_UNIT" },
  });

  const {
    loading: preservationLevelsLoading,
    error: preservationLevelsError,
    data: preservationLevelsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "PRESERVATION_LEVEL" },
  });

  const {
    loading: statusLoading,
    error: statusError,
    data: statusData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "STATUS" },
  });

  const {
    loading: visibilityLoading,
    error: visibilityError,
    data: visibilityData,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "VISIBILITY" } });

  return (
    <div
      className="columns is-multiline"
      data-testid="project-status-metadata"
      {...restProps}
    >
      <div className="column is-one-third" data-testid="preservationLevel">
        <UIFormField label="Preservation Level">
          <div className="select">
            <select name="preservationLevel" ref={register()}>
              <option value="">-- Select --</option>
              {preservationLevelsData &&
                preservationLevelsData.codeList.map((item) => (
                  <option
                    key={item.id}
                    value={JSON.stringify({
                      id: item.id,
                      scheme: "PRESERVATION_LEVEL",
                      label: item.label,
                    })}
                  >
                    {item.label}
                  </option>
                ))}
            </select>
          </div>
        </UIFormField>
      </div>
      <div className="column is-one-third" data-testid="status">
        <UIFormField label="Status">
          <div className="select">
            <select name="status" ref={register()}>
              <option value="">-- Select --</option>
              {statusData &&
                statusData.codeList.map((item) => (
                  <option
                    key={item.id}
                    value={JSON.stringify({
                      id: item.id,
                      scheme: "STATUS",
                      label: item.label,
                    })}
                  >
                    {item.label}
                  </option>
                ))}
            </select>
          </div>
        </UIFormField>
      </div>
      <div className="column is-one-third" data-testid="visibility">
        <UIFormField label="Visibility">
          <div className="select">
            <select name="visibility" ref={register()}>
              <option value="">-- Select --</option>
              {visibilityData &&
                visibilityData.codeList.map((item) => (
                  <option
                    key={item.id}
                    value={JSON.stringify({
                      id: item.id,
                      scheme: "VISIBILITY",
                      label: item.label,
                    })}
                  >
                    {item.label}
                  </option>
                ))}
            </select>
          </div>
        </UIFormField>
      </div>
      <div className="column is-one-third" data-testid="projectCycle">
        <UIFormField label="Project Cycle">
          <UIFormInput
            data-testid="project-cycle"
            isReactHookForm
            placeholder="Project Cycle"
            name="projectCycle"
            label="Project Cycle"
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAdministrativeProjectStatusMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAdministrativeProjectStatusMetadata;
