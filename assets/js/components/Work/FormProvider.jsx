import React from "react";
import PropTypes from "prop-types";

export const WorkFormContext = React.createContext();

const WorkFormProvider = ({ children, isEditing }) => {
  return (
    <WorkFormContext.Provider value={isEditing}>
      {children}
    </WorkFormContext.Provider>
  );
};

WorkFormProvider.propTypes = {
  children: PropTypes.node,
  isEditing: PropTypes.bool
};

export default WorkFormProvider;
