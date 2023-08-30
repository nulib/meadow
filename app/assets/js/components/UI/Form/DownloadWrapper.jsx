import PropTypes from "prop-types";
import React from "react";

function DownloadWrapper({ formAction, queryValue, children }) {
  return (
    <form method="POST" action={formAction} className="block">
      {queryValue && (
        <input
          type="hidden"
          name="query"
          value={JSON.stringify({ query: queryValue })}
        />
      )}
      {children}
    </form>
  );
}

DownloadWrapper.propTypes = {
  formAction: PropTypes.string.isRequired,
  queryValue: PropTypes.object,
};

export default DownloadWrapper;
