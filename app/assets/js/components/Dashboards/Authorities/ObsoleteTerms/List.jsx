import { Button, Notification } from "@nulib/design-system";
import { GET_OBSOLETE_CONTROLLED_TERMS } from "@js/components/Dashboards/dashboards.gql";
import { IconImages } from "@js/components/Icon";
import { useHistory } from "react-router-dom";
import { useQuery } from "@apollo/client/react";

import React from "react";

const colHeaders = ["Obsolete URI", "Obsolete Label", "Replacement URI", "Replacement Label"];

export default function DashboardsObsoleteTermsList() {
  const history = useHistory();
  const [authorities, setAuthorities] = React.useState([]);
  const [limit, setLimit] = React.useState(100);

  // GraphQL
  const { loading, error, data } = useQuery(GET_OBSOLETE_CONTROLLED_TERMS, {
    variables: { limit },
    pollInterval: 10000,
  });

  const limitOptions = [25, 50, 100, 500];

  function filterValues() {
    if (!data) return;
    setAuthorities([...data.obsoleteControlledTerms]);
  }

  React.useEffect(() => {
    if (!data) return;
    filterValues();
  }, [data, limit]);

  if (loading) return null;
  if (error) return <Notification isDanger>{error.toString()}</Notification>;

  const handleViewClick = (value) => {
    history.push("/search", {
      passedInSearchTerm: `all_controlled_ids:\"${value}\"`,
    });
  };

  return (
    <React.Fragment>
      <div
        className="is-flex is-justify-content-flex-end is-align-items-center mb-5"
        data-testid="obsolete-terms-dashboard-table-options"
      >
        <label className="is-flex is-align-items-center columns is-3">
          <span className="column">Item Count</span>
          <div className="is-flex is-align-items-center column">
            {limitOptions.map((option) => {
              return (
                <button
                  key={option}
                  className={`button ${limit === option ? "is-primary active" : "is-ghost"}`}
                  onClick={() => setLimit(option)}
                >
                  {option}
                </button>
              );
            })}
          </div>
        </label>
      </div>

      <div className="table-container">
        <table
          className="table is-striped is-fullwidth"
          data-testid="obsolete-terms-dashboard-table"
        >
          <thead>
            <tr>
              {colHeaders.map((col) => (
                <th key={col}>{col}</th>
              ))}
              <th></th>
            </tr>
          </thead>
          <tbody data-testid="obsolete-terms-table-body">
            {authorities.map((record) => {
              const { id = "", label = "", replacedBy = "", replacementLabel = "" } = record;

              return (
                <tr key={id} data-testid="obsolete-terms-row">
                  <td><a href={id} target="_blank" rel="noopener noreferrer">{id}</a></td>
                  <td>{label}</td>
                  <td><a href={replacedBy} target="_blank" rel="noopener noreferrer">{replacedBy}</a></td>
                  <td>{replacementLabel}</td>

                  <td className="has-text-right is-right mb-0">
                    <div className="field is-grouped">
                      <Button
                        onClick={() => handleViewClick(id)}
                        isLight
                        data-testid="button-to-search"
                        title="View works containing this record"
                      >
                        <IconImages />
                      </Button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </React.Fragment>
  );
}
