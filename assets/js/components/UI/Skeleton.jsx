import React from "react";
import PropTypes from "prop-types";

// Reference: https://cssninja.io/blog/post/facebook-placeholders

const UISkeleton = ({ type = "text", rows = 10 }) => {
  const buildRows = () => {
    let arr = [];
    for (let i = 0; i < rows; i++) {
      arr.push(<div key={i} className="content-shape loads"></div>);
    }
    return arr;
  };

  return (
    <div className="loader-wrapper is-active">
      <div className="placeload">
        {type === "text" && (
          <div className="header">
            <div className="header-content">{buildRows()}</div>
          </div>
        )}
        {type === "full" && (
          <>
            <div className="header">
              <div className="img loads"></div>
              <div className="header-content">
                <div className="content-shape loads"></div>
                <div className="content-shape loads"></div>
              </div>
            </div>
            <div className="image-placeholder loads"></div>
            <div className="placeholder-footer">
              <div className="footer-block">
                <div className="content-shape loads"></div>
                <div className="content-shape loads"></div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

UISkeleton.propTypes = {
  loading: PropTypes.bool,
  rows: PropTypes.number,
  type: PropTypes.oneOf(["text", "full"]),
};

export default UISkeleton;
