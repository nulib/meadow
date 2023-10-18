import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import { GET_CURRENT_USER_QUERY } from "@js/components/Auth/auth.gql";
import { Notification } from "@nulib/design-system";

/**
 * More info in the Docs:
 * http://docs.rdc.library.northwestern.edu/1._User_Guides/Meadow/5._Administration/Role-Based-Authorization/
 */

// Order of role-based access low to high
const userRoleHierarchy = ["USER", "EDITOR", "MANAGER", "ADMINISTRATOR"];

export default function useIsAuthorized() {
  const { data, loading, error } = useQuery(GET_CURRENT_USER_QUERY);

  if (loading) return;
  if (error)
    return (
      <Notification isDanger>
        Error retrieving Current User GraphQL query
      </Notification>
    );

  /**
   * Determine whether user is authorized to view the component
   * @param {String} componentAuthLevel A user must at least meet this role for the component to be displayed
   */
  function isAuthorized(componentAuthLevel = "EDITOR") {
    const userRoleIndex = userRoleHierarchy.indexOf(data.me.role);
    const componentRoleIndex = userRoleHierarchy.indexOf(
      componentAuthLevel.toUpperCase(),
    );
    if (userRoleIndex >= componentRoleIndex) {
      return true;
    }
    return false;
  }

  return {
    user: data.me,
    isAuthorized,
  };
}
