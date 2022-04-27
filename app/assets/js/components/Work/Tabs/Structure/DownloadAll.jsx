import React from "react";
import PropTypes from "prop-types";

function WorkTabsStructureDownloadAll(props) {
  return (
    <div className="box">
      <h3 className="subtitle">Download all files as zip</h3>
      <div className="columns">
        <div className="column">
          <div className="field">
            <input
              type="radio"
              className="is-checkradio"
              name="downloadsize"
              id="downloadsize1"
            />
            <label htmlFor="downloadsize1"> Full size</label>
            <input
              type="radio"
              className="is-checkradio"
              name="downloadsize"
              id="downloadsize2"
            />
            <label htmlFor="downloadsize2"> 3000x3000</label>
            <input
              type="radio"
              className="is-checkradio"
              name="downloadsize"
              id="downloadsize3"
            />
            <label htmlFor="downloadsize3"> 1000x1000</label>
          </div>
        </div>

        <div className="column buttons has-text-right">
          <button className="button">Download Tifs</button>
          <button className="button">Download JPGs</button>
        </div>
      </div>
    </div>
  );
}

WorkTabsStructureDownloadAll.propTypes = {};

export default WorkTabsStructureDownloadAll;
