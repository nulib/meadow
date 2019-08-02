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
      inserted_at
      updated_at
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
            {data.projects.length > 0 &&
              data.projects.map(({ id, folder, title }) => (
                <article key={id} className="pb-6">
                  <h3>
                    <Link to={`/project/${id}`}>{title}</Link>
                  </h3>
                  <p>
                    <span className="font-bold">s3 Bucket Folder: </span>{" "}
                    <a href="#">{folder}</a>
                  </p>
                </article>
              ))}
          </section>
        );
      }}
    </Query>
  );
};

export default ProjectList;
export { GET_PROJECTS_QUERY };
