import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { GET_INGEST_JOBS, DELETE_INGEST_JOB } from "./inventorySheet.query";
import { useApolloClient, useMutation } from "@apollo/react-hooks";

const InventorySheetList = ({ projectId }) => {
  const { loading, error, data } = useQuery(GET_INGEST_JOBS, {
    variables: { projectId }
  });
  const client = useApolloClient();
  const [deleteIngestJob, { data: deleteIngestJobData }] = useMutation(
    DELETE_INGEST_JOB,
    {
      update(
        cache,
        {
          data: { deleteIngestJob }
        }
      ) {
        try {
          const { project } = client.readQuery({
            query: GET_INGEST_JOBS,
            variables: { projectId }
          });

          const index = project.ingestJobs.findIndex(
            ingestJob => ingestJob.id === deleteIngestJob.id
          );

          project.ingestJobs.splice(index, 1);

          client.writeQuery({
            query: GET_INGEST_JOBS,
            data: { project }
          });
        } catch (error) {
          console.log("Error reading from cache", error);
        }
      }
    }
  );

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const handleDeleteClick = ingestJobId => {
    console.log("TCL: handleDeleteClick -> ingestJobId", ingestJobId);
    deleteIngestJob({ variables: { ingestJobId } });
  };

  return (
    <div>
      {data.project.ingestJobs.length === 0 && (
        <p data-testid="no-inventory-sheets-notification">
          No inventory sheets are found.
        </p>
      )}

      {data.project.ingestJobs.length > 0 && (
        <table>
          <caption>All Project Ingest Jobs</caption>
          <thead>
            <tr>
              <th>Ingest job title</th>
              <th>Last updated</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {data.project.ingestJobs.map(
              ({ id, name, filename, updatedAt }) => (
                <tr key={id}>
                  <td>
                    <Link to={`/project/${projectId}/inventory-sheet/${id}`}>
                      {name}
                    </Link>
                  </td>
                  <td>{updatedAt}</td>
                  <td>[ supported? ]</td>
                  <td>
                    <button onClick={() => handleDeleteClick(id)}>
                      Delete
                    </button>
                  </td>
                </tr>
              )
            )}
          </tbody>
        </table>
      )}
    </div>
  );
};

InventorySheetList.propTypes = {
  projectId: PropTypes.string.isRequired
};

export default InventorySheetList;
