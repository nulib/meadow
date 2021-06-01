import React from "react";
import PropTypes from "prop-types";

function FormDownloadWrapper({ formAction, queryValue, children }) {
  return (
    <form method="POST" action={formAction} className="block">
      <input
        type="hidden"
        name="query"
        value={JSON.stringify({ query: queryValue })}
      />
      {children}
    </form>
  );
}

FormDownloadWrapper.propTypes = {
  formAction: PropTypes.string.isRequired,
  queryValue: PropTypes.object,
};

export default FormDownloadWrapper;
