import React from "react";
import { Link } from "react-router-dom";
import gql from "graphql-tag";
import { Query } from "react-apollo";
import Error from "../UI/Error";
import Loading from "../UI/Loading";

const GET_PROJECTS_QUERY = gql`
  query GetProjects {
    projects {
      id
      title
      folder
      updated_at
      ingestJobs {
        id
      }
    }
  }
`;

const ProjectList = () => {
  return (
    <Query query={GET_PROJECTS_QUERY}>
      {({ data, loading, error }) => {
        if (loading) return <Loading />;
        if (error) return <Error error={error} />;
        return (
          <section className="my-6">
            <table>
              <thead>
                <tr>
                  <th>Project</th>
                  <th>s3 Bucket Folder</th>
                  <th>Number of ingestion jobs</th>
                  <th>Last Updated</th>
                </tr>
              </thead>
              <tbody>
                {data.projects.length > 0 &&
                  data.projects.map(
                    ({ id, folder, title, updated_at, ingestJobs }) => (
                      <tr key={id}>
                        <td>
                          <Link to={`/project/${id}`}>{title}</Link>
                        </td>
                        <td>{folder}</td>
                        <td className="text-center">{ingestJobs.length}</td>
                        <td>{updated_at}</td>
                      </tr>
                    )
                  )}
              </tbody>
            </table>
          </section>
        );
      }}
    </Query>
  );
};

export default ProjectList;
export { GET_PROJECTS_QUERY };
