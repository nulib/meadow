import React from "react";
import { Link } from "react-router-dom";
import ProjectList from "../../components/Project/List";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import AddOutlineIcon from "../../../css/fonts/zondicons/add-outline.svg";

const ScreensProjectList = () => {
  return (
    <>
      <ScreenHeader
        title="Ingestion Projects"
        description="The following is a list of all active Ingestion Projects"
        breadCrumbs={[{ label: "Projects", link: "/project/list" }]}
      />
      <ScreenContent>
        <Link to="/project/create" className="btn">
          <AddOutlineIcon className="icon" />
          Create Project
        </Link>
        <ProjectList />
      </ScreenContent>
    </>
  );
};

export default ScreensProjectList;
