import React from "react";
import Main from "../components/Main";
import { mockProjects } from "../mock-data/projects";
import { Link } from "react-router-dom";
import axios from "axios";

export default class IngestPage extends React.Component {
  state = {
    projects: []
  };

  componentDidMount() {
    this.getProjects();
  }

  async getProjects() {
    try {
      const response = await axios.get("api/v1/projects");
      this.setState({ projects: response.data.data });
    } catch (error) {
      console.log("getProjects() error", error);
    }
  }

  render() {
    const { projects } = this.state;

    return (
      <Main>
        <h1>Ingestion Projects</h1>
        <Link to="/create-ingest-project" className="btn">
          Create Project
        </Link>
        <h2 className="mt-12">Real system output</h2>
        <section className="my-6 content-block">
          {projects.map(({ id, folder, title }) => (
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

        <h2 className="mt-12">
          Example Output (should it look something like this?)
        </h2>
        <section className="my-6 content-block">
          {mockProjects.map(
            ({
              id,
              title,
              numWorks,
              numFilesets,
              numInventorySheets,
              dateLastModified,
              s3Folder
            }) => (
              <article key={id} className="pb-6">
                <h3>
                  <a href="#">{title}</a>
                </h3>
                <p>
                  {numWorks} Works | {numFilesets} Filesets |{" "}
                  {numInventorySheets} Inventory Sheets
                </p>
                <p>
                  <span className="font-bold">s3 Bucket Folder: </span>{" "}
                  <a href="#">{s3Folder}</a>
                </p>
                <p>
                  <span className="font-bold">Date Last Modified: </span>
                  {dateLastModified}
                </p>
              </article>
            )
          )}
        </section>
      </Main>
    );
  }
}
