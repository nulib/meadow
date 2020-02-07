import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

const WorkTabAbout = ({ work }) => {
  return (
    <div className="columns is-centered">
      <div className="column is-three-quarters">
        <div className="box">
          <h3 className="is-size-5 title">Description</h3>
          <p>
            For my birthday I got a humidifier and a de-humidifier. I put them
            in the same room and let them fight it out.For my birthday I got a
            humidifier and a de-humidifier. I put them in the same room and let
            them fight it out. For my birthday I got a humidifier and a
            de-humidifier. I put them in the same room and let them fight it
            out.For my birthday I got a humidifier and a de-humidifier. I put
            them in the same room and let them fight it out. For my birthday I
            got a humidifier and a de-humidifier. I put them in the same room
            and let them fight it out
          </p>
        </div>
        <div className="box">
          <h3 className="is-size-5 title">Date Created</h3>
          <p>asfdafs </p>
        </div>
        <div className="box">
          <h3 className="is-size-5 title">Creators</h3>
          <ul>
            <li>
              <Link to="/">Creator 1 as a link</Link>
            </li>
            <li>
              <Link to="/">Creator 2 as a link</Link>
            </li>
            <li>
              <Link to="/">Creator 3 as a link</Link>
            </li>
          </ul>
        </div>
        <div className="box">
          <h3 className="is-size-5 title">Contributors</h3>
          <ul>
            <li>
              <Link to="/">Contributor 1 as a link</Link>
            </li>
            <li>
              <Link to="/">Contributor 2 as a link</Link>
            </li>
            <li>
              <Link to="/">Contributor 3 as a link</Link>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

WorkTabAbout.propTypes = {
  work: PropTypes.object
};

export default WorkTabAbout;
