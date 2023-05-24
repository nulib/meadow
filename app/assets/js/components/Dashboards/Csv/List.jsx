import { IconImages, IconView } from "@js/components/Icon";

import DashboardsCsvStatus from "@js/components/Dashboards/Csv/Status";
import { GET_CSV_METADATA_UPDATE_JOBS } from "@js/components/Dashboards/dashboards.gql";
import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import React from "react";
import UIFormInput from "@js/components/UI/Form/Input";
import UISearchBarRow from "@js/components/UI/SearchBarRow";
import { formatDate } from "@js/services/helpers";
import { useQuery } from "@apollo/client";

const displayFields = [
  {
    label: "Filename",
    graphQLProperty: "filename",
  },
  {
    label: "Status",
    graphQLProperty: "status",
  },
  {
    label: "User",
    graphQLProperty: "user",
  },
  {
    label: "Started at",
    graphQLProperty: "startedAt",
  },
  {
    label: "Updated at",
    graphQLProperty: "updatedAt",
  },
];

function DashboardsCsvList(props) {
  const [filteredCsv, setFilteredCsv] = React.useState([]);

  // GraphQL
  const { loading, error, data } = useQuery(GET_CSV_METADATA_UPDATE_JOBS, {
    pollInterval: 1000,
  });

  React.useEffect(() => {
    if (!data) {
      return;
    }
    setFilteredCsv(
      data.csvMetadataUpdateJobs && data.csvMetadataUpdateJobs.length > 0
        ? data.csvMetadataUpdateJobs
        : []
    );
  }, [data]);

  const handleFilterChange = (e) => {
    const filterValue = e.target.value.toUpperCase();
    if (!filterValue) {
      return setFilteredCsv(data.csvMetadataUpdateJobs);
    }
    const newList = filteredCsv.filter((item) => {
      return item.filename.toUpperCase().indexOf(filterValue) > -1;
    });
    setFilteredCsv(newList);
  };

  return (
    <div data-testid="csv-list">
      <UISearchBarRow isCentered>
        <UIFormInput
          placeholder="Filter"
          name="csvSearch"
          label="Filter CSV imports"
          onChange={handleFilterChange}
          data-testid="input-csv-filter"
        />
      </UISearchBarRow>
      <div className="table-container">
        <table
          className="table is-striped is-fullwidth"
          data-testid="local-csv-table"
        >
          <thead>
            <tr>
              {displayFields.map(({ label }) => (
                <th key={label}>{label}</th>
              ))}
              <th></th>
            </tr>
          </thead>
          <tbody data-testid="csv-table-body">
            {filteredCsv.map((record) => {
              const {
                id,
                filename = "",
                startedAt = "",
                status = "",
                updatedAt = "",
                user = "",
              } = record;

              return (
                <tr key={id} data-testid="csv-row">
                  <td>{filename}</td>
                  <td>
                    <DashboardsCsvStatus status={status} />
                  </td>
                  <td>{user}</td>
                  <td>{formatDate(startedAt)}</td>
                  <td>{formatDate(updatedAt)}</td>

                  <td>
                    <div className="field is-grouped is-justify-content-flex-end">
                      <Link
                        to={`/dashboards/csv-metadata-update/${id}`}
                        className="button is-light"
                        data-testid="view-button"
                        title="View Metadata Update Job details"
                      >
                        <IconView />
                      </Link>
                      {status.toUpperCase() === "COMPLETE" && (
                        <Link
                          data-testid="button-to-search"
                          className="button is-light"
                          title="View updated works"
                          to={{
                            pathname: "/search",
                            state: {
                              passedInSearchTerm: `csv_metadata_update_jobs:\"${id}\"`,
                            },
                          }}
                        >
                          <IconImages />
                        </Link>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

DashboardsCsvList.propTypes = {};

export default DashboardsCsvList;
