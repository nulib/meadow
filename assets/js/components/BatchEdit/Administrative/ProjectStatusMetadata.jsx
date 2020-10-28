import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormInput from "../../UI/Form/Input";
import { useFormContext } from "react-hook-form";
import { useCodeLists } from "@js/context/code-list-context";

const BatchEditAdministrativeProjectStatusMetadata = ({ ...restProps }) => {
  const context = useFormContext();
  const register = context.register;
  const codeLists = useCodeLists();

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
              {codeLists.preservationLevelData &&
                codeLists.preservationLevelData.codeList.map((item) => (
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
              {codeLists.statusData &&
                codeLists.statusData.codeList.map((item) => (
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
              {codeLists.visibilityData &&
                codeLists.visibilityData.codeList.map((item) => (
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
