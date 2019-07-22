import React from "react";
import { Link } from "react-router-dom";
import ProjectList from "../../components/Project/List";

const ScreensProjectList = () => {
  return (
    <>
      <h1>Ingestion Projects</h1>
      <Link to="/project/create" className="btn">
        Create Project
      </Link>
      <ProjectList />
    </>
  );
};

export default ScreensProjectList;
