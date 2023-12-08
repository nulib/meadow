import React from "react";
import PropTypes from "prop-types";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
function AuthDisplayAuthorized({ level, children }) {
  const { isAuthorized } = useIsAuthorized();
  if (!isAuthorized(level)) {
    return null;
  }
  return <>{children}</>;
}

AuthDisplayAuthorized.propTypes = {
  level: PropTypes.oneOf(["USER", "EDITOR", "MANAGER", "ADMINISTRATOR", "SUPERUSER"]),
  children: PropTypes.node,
};

export default AuthDisplayAuthorized;
