import React from "react";
import { useMutation } from "@apollo/client";
import { ASSUME_ROLE } from "@js/components/Role/role.gql.js";
import { GET_CURRENT_USER_QUERY } from "@js/components/Auth/auth.gql";
import { toastWrapper } from "@js/services/helpers";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const nestedDropdown = css`
  &:hover > .dropdown-menu {
    display: block;
  }
  .dropdown-menu {
    top: -15px;
    margin-left: 80%;
  }
  .dropdown-trigger {
    button::after {
      content: "⦠";
    }
    button {
      padding: 0px 0px;
      border: 0px;
      font-size: 14px;
      font-weight: 400;
      height: 2em;
    }
  }
`;

const RoleNavDropdown = () => {
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
    <div css={nestedDropdown} className="nested navbar-item dropdown">
      <div className="dropdown-trigger">
        <button
          className="button"
          aria-haspopup="true"
          aria-controls="dropdown-menu"
        >
          <span>Assume Role</span>
          <span className="icon is-small">
            <i className="fas fa-angle-down" aria-hidden="true"></i>
          </span>
        </button>
      </div>
      <div className="dropdown-menu" id="dropdown-menu" role="menu">
        <div className="dropdown-content">
          <a
            href="#"
            className="dropdown-item"
            onClick={() => handleRoleChange("MANAGER")}
          >
            Manager
          </a>
          <a
            className="dropdown-item"
            onClick={() => handleRoleChange("EDITOR")}
          >
            Editor
          </a>
          <a
            href="#"
            className="dropdown-item"
            onClick={() => handleRoleChange("USER")}
          >
            User
          </a>
        </div>
      </div>
    </div>
  );
};

export default RoleNavDropdown;
