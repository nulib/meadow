import React from "react";
import PropTypes from "prop-types";
import { useAuthState } from "@js/components/Auth/Auth";

const roleBasedActions = {
  ADMINISTRATOR: ["delete", "edit", "save"],
  EDITOR: ["edit", "save"],
  MANAGER: ["edit", "save", "delete"],
  USER: [],
};

export const DisplayAuthorized = ({ action, children }) => {
  const authState = useAuthState();
  const allowedUserActions = roleBasedActions[authState.role];

  if (allowedUserActions.indexOf(action) > -1) {
    return children;
  }
  return null;
};

DisplayAuthorized.propTypes = {
  action: PropTypes.string,
  children: PropTypes.node,
};
