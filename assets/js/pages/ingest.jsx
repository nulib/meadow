import React from "react";
import Main from "../components/Main";
import { projects } from "../mock-data/projects";
import { Link } from "react-router-dom";

export default class IngestPage extends React.Component {
  render() {
    return (
      <Main>
        <h1>Ingestion Projects</h1>
        <Link to="/create-ingest-project" className="btn">
          Create Project
        </Link>
        <section className="my-6 content-block">
          {projects.map(
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
