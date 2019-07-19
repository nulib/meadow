import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import axios from "axios";

const InventorySheetList = ({ projectId }) => {
  const [inventorySheets, setInventorySheets] = useState([]);
  const url = "/api/v1/ingest_jobs";

  useEffect(() => {
    // Start it off by assuming the component is still mounted
    let mounted = true;

    const loadData = async () => {
      const response = await axios.get(url);
      // We have a response, but let's first check if component is still mounted
      if (mounted) {
        setInventorySheets(response.data.data);
      }
    };
    loadData();

    return () => {
      // When cleanup is called, toggle the mounted variable to false
      mounted = false;
    };
  }, [url]);

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
                  {sheet.name}
                </Link>
              </p>
              <p>Filename: ${sheet.filename}</p>
              <p>Total Works: xxx</p>
              <p>Ingested: 2019-05-12</p>
              <p>Creator: Some person</p>
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
