import React, { useEffect, useState } from "react";
import axios from "axios";
import { Link } from "react-router-dom";

const ProjectList = () => {
  const [projects, setProjects] = useState([]);
  const url = "/api/v1/projects";

  useEffect(() => {
    let mounted = true;

    const loadData = async () => {
      const response = await axios.get(url);
      if (mounted) {
        setProjects(response.data.data);
      }
    };
    loadData();

    return () => {
      // When cleanup is called, toggle the mounted variable to false
      mounted = false;
    };
  }, [url]);

  return (
    <section className="my-6">
      {projects.length > 0 &&
        projects.map(({ id, folder, title }) => (
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
};

export default ProjectList;
