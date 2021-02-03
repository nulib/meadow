import React, { useState, useContext } from "react";
import { useMutation } from "@apollo/client";
import { AuthContext } from "@js/components/Auth/Auth";
import UILayoutNavDropdown from "@js/components/UI/Layout/NavDropdown";
import UILayoutNavDropdownHeader from "@js/components/UI/Layout//NavDropdownHeader";
import UILayoutNavDropdownBody from "@js/components/UI/Layout/NavDropdownBody";
import UILayoutNavDropdownItem from "@js/components/UI/Layout/NavDropdownItem";
import { ASSUME_ROLE } from "@js/components/Role/role.gql.js";
import { GET_CURRENT_USER_QUERY } from "@js/components/Auth/auth.gql";
import { toastWrapper } from "@js/services/helpers";

const RoleNavDropdown = () => {
  const currentUser = useContext(AuthContext);
  const [activeHoverNav, setActiveHoverNav] = useState("adam");

  const [assumeRole] = useMutation(ASSUME_ROLE, {
    onCompleted({ assumeRole }) {
      toastWrapper(
        "is-success",
        "Your role has been temporarily changed. To change back, log out and then in again."
      );
    },
    onError(error) {
      console.log("onError() error", error);
      toastWrapper(
        "is-danger",
        "An error occured. Your role could not be updated."
      );
    },
    refetchQueries(_mutationResult) {
      return [{ query: GET_CURRENT_USER_QUERY }];
    },
  });

  const handleRoleChange = (userRole) => {
    assumeRole({ variables: { userRole: userRole } });
  };

  return (
    <UILayoutNavDropdown
      onMouseEnter={() => setActiveHoverNav("Roles")}
      onMouseLeave={() => setActiveHoverNav("")}
    >
      <UILayoutNavDropdownHeader label="roles">
        Change Role
      </UILayoutNavDropdownHeader>
      <UILayoutNavDropdownBody isExpanded={activeHoverNav === "roles"}>
        <UILayoutNavDropdownItem>
          <a
            role="menuitem"
            className="navbar-item"
            onClick={() => handleRoleChange("MANAGER")}
          >
            Manager
          </a>
        </UILayoutNavDropdownItem>
        <UILayoutNavDropdownItem>
          <a
            role="menuitem"
            className="navbar-item"
            onClick={() => handleRoleChange("EDITOR")}
          >
            Editor
          </a>
        </UILayoutNavDropdownItem>
        <UILayoutNavDropdownItem>
          <a
            role="menuitem"
            className="navbar-item"
            onClick={() => handleRoleChange("USER")}
          >
            User
          </a>
        </UILayoutNavDropdownItem>
      </UILayoutNavDropdownBody>
    </UILayoutNavDropdown>
  );
};

export default RoleNavDropdown;
