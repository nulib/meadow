import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const WorkTabsStructure = ({ work }) => {
  if (!work) {
    return null;
  }
  return (
    <div className="columns is-centered">
      <div className="column is-three-quarters">
        {work.fileSets.map(({ id, accessionNumber, metadata }) => (
          <article key={id} className="media">
            <figure className="media-left">
              <p className="image is-64x64">
                <img src="https://bulma.io/images/placeholders/128x128.png" />
              </p>
            </figure>
            <div className="media-content">
              <div className="content">
                <p>
                  <strong>{accessionNumber}</strong>
                  <br />
                  {metadata.description}
                </p>
              </div>
            </div>
            <div className="media-right">
              <button className="button">
                <FontAwesomeIcon icon="file-download" /> .tiff
              </button>
              <button className="button">
                <FontAwesomeIcon icon="file-download" /> .jpg
              </button>
            </div>
          </article>
        ))}

        <section className="section has-background-light">
          <h2 className="small-title">Download all files as zip</h2>
          <div className="columns">
            <div className="column">
              <div className="control">
                <label className="radio">
                  <input type="radio" name="downloadsize" /> Full size
                </label>
                <label className="radio">
                  <input type="radio" name="downloadsize" /> 3000x3000
                </label>
                <label className="radio">
                  <input type="radio" name="downloadsize" /> 1000x1000
                </label>
              </div>
            </div>

            <div className="column buttons has-text-right">
              <button className="button">Download Tiffs</button>
              <button className="button is-primary">Download JPGs</button>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

WorkTabsStructure.propTypes = {
  work: PropTypes.object
};

export default WorkTabsStructure;
