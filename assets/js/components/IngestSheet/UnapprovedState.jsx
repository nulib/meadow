import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";

const IngestSheetUnapprovedState = ({ validations }) => {
  const [groupings, setGroupings] = useState();

  useEffect(() => {
    orderRows(validations);
  }, [validations]);

  function orderRows(validations = []) {
    const workMap = new Map();

    validations.forEach(row => {
      const workObj = row.fields.find(
        field => field.header === "work_accession_number"
      );
      const workAccessionNumber = workObj.value;
      let filesetObj = {};

      if (!workMap.get(workAccessionNumber)) {
        workMap.set(workAccessionNumber, []);
      }

      const otherFields = row.fields.filter(
        field => field.header !== "work_accession_number"
      );
      otherFields.forEach(field => {
        filesetObj[field.header] = field.value;
      });

      workMap.get(workAccessionNumber).push(filesetObj);
    });

    setGroupings(workMap);
  }

  function renderGroupings() {
    if (groupings) {
      // Convert from Map to Array object allowing the "map" method
      // so React can display the results
      const groupingsArray = [...groupings];

      return groupingsArray.map(grouping => {
        const work = grouping[0];
        const filesets = grouping[1];

        return (
          <tbody key={work}>
            {filesets.map(({ accession_number, description }, i) => (
              <tr key={accession_number}>
                {i === 0 && (
                  <td rowSpan={filesets.length}>
                    <strong>{work}</strong>
                  </td>
                )}
                <td>{accession_number}</td>
                <td>{description}</td>
              </tr>
            ))}
          </tbody>
        );
      });
    }
  }

  return (
    <table className="mb-6">
      <thead>
        <tr>
          <th>Work Accession Number</th>
          <th>Fileset Accession Number</th>
          <th>Fileset Data</th>
        </tr>
      </thead>
      {renderGroupings()}
    </table>
  );
};

IngestSheetUnapprovedState.propTypes = {
  validations: PropTypes.arrayOf(PropTypes.object)
};

export default IngestSheetUnapprovedState;
