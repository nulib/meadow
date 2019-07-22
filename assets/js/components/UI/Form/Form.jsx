import React from "react";
import PropTypes from "prop-types";

const UIForm = ({ children, testId = "", classes = "", onSubmit }) => (
  <form data-testid={testId} className={classes} onSubmit={onSubmit}>
    {children}
  </form>
);

UIForm.propTypes = {
  classes: PropTypes.string,
  onSubmit: PropTypes.func.isRequired,
  testId: PropTypes.string
};

export default UIForm;
