import React from "react";
import PropTypes from "prop-types";
import moment from "moment";

function UIDate({ dateString }) {
  if (!dateString) return null;

  return (
    <React.Fragment>
      {moment(dateString).format("MMM DD, YYYY h:mm A")}
    </React.Fragment>
  );
}

UIDate.propTypes = {
  dateString: PropTypes.string,
};

export default UIDate;
