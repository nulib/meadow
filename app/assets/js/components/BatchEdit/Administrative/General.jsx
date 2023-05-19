import PropTypes from "prop-types";
import React from "react";
import UIFormField from "../../UI/Form/Field";
import { useCodeLists } from "@js/context/code-list-context";
import { useFormContext } from "react-hook-form";

const BatchEditAdministrativeGeneral = ({ ...restProps }) => {
  const context = useFormContext();
  const register = context.register;
  const codeLists = useCodeLists();

  return (
    <div data-testid="project-status-metadata" {...restProps}>
      <UIFormField label="Library Unit" data-testid="libraryUnit">
        <div className="select">
          <select {...register("libraryUnit")}>
            <option value="">-- Select --</option>
            {codeLists.libraryUnitData &&
              codeLists.libraryUnitData.codeList.map((item) => (
                <option
                  key={item.id}
                  value={JSON.stringify({
                    id: item.id,
                    scheme: "LIBRARY_UNIT",
                    label: item.label,
                  })}
                >
                  {item.label}
                </option>
              ))}
          </select>
        </div>
      </UIFormField>

      <UIFormField label="Preservation Level" data-testid="preservationLevel">
        <div className="select">
          <select {...register("preservationLevel")}>
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

      <UIFormField label="Status" data-testid="status">
        <div className="select">
          <select {...register("status")}>
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

      <UIFormField label="Visibility" data-testid="visibility">
        <div className="select">
          <select {...register("visibility")}>
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
  );
};

BatchEditAdministrativeGeneral.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAdministrativeGeneral;
