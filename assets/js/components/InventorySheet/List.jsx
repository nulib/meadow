import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { mockInventorySheets } from "../../mock-data/inventorySheets";
import { Link } from "react-router-dom";

const InventorySheetList = ({ projectId }) => {
  const [inventorySheets, setInventorySheets] = useState([]);

  useEffect(() => {
    // Get inventory sheets for project based on id
    getInventorySheets();
  });

  function getInventorySheets() {
    setInventorySheets(mockInventorySheets);
  }

  return (
    <div>
      {inventorySheets.length === 0 && (
        <p data-testid="no-inventory-sheets-notification">
          No inventory sheets are found.
        </p>
      )}

      {inventorySheets.length > 0 && (
        <ul data-testid="inventory-sheet-list">
          {inventorySheets.map(sheet => (
            <li key={sheet.id} className="pb-4">
              <p>
                <Link to={`/project/${projectId}/inventory-sheet/${sheet.id}`}>
                  {sheet.title}
                </Link>
              </p>
              <p>Total Works: {sheet.totalWorks}</p>
              <p>Ingested: {sheet.dateCreated}</p>
              <p>Creator: {sheet.creator}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

InventorySheetList.propTypes = {
  projectId: PropTypes.string.isRequired
};

export default InventorySheetList;
