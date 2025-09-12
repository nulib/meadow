import { Notification } from "@nulib/design-system";
import { LIST_ROLES_QUERY, LIST_USERS_QUERY, SET_USER_ROLE_MUTATION } from "@js/components/Auth/auth.gql";
import { useMutation, useQuery } from "@apollo/client/react";

import React from "react";
import { toastWrapper } from "@js/services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import { IconTrashCan } from "@js/components/Icon";
import UIFormInput from "@js/components/UI/Form/Input";

const colHeaders = ["Username", "Display Name", "Email", "Role"];

export default function DashboardsUsersList() {
  const [roles, setRoles] = React.useState([]);
  const [users, setUsers] = React.useState([]);

  const { error: usersError, refetch: refetchUsers } = useQuery(LIST_USERS_QUERY, {
    onCompleted: (data) => {
      setUsers([...data.users]);
    },
  });

  const { error: rolesError } = useQuery(LIST_ROLES_QUERY, {
    onCompleted: (data) => {
      setRoles([...data.roles]);
    },
  });

  const [setUserRole, { error: updateError, loading: updateLoading }] =
    useMutation(SET_USER_ROLE_MUTATION, {
      onCompleted({ setUserRole }) {
        toastWrapper("is-success", setUserRole.message);
        refetchUsers().then(({ data }) => {
          setUsers([...data.users]);
        })
      }
    });

  if (updateError)
    return <Notification isDanger>{updateError.toString()}</Notification>;

  const handleRoleSelect = (record, value) => {
    setUserRole({
      variables: {
        userId: record.username,
        userRole: value,
      },
    })
  };

  const methods = useForm({
    defaultValues: {
      username: "",
    },
  });

  const onSubmit = (data) => {
    setUserRole({
      variables: {
        userId: data.username,
        userRole: "USER",
      },
    });
    methods.reset();
  };

  if (!users || !roles) return null;
  if (usersError) return <Notification isDanger>{usersError.toString()}</Notification>;
  if (rolesError) return <Notification isDanger>{rolesError.toString()}</Notification>;

  return (
    <React.Fragment>
      <FormProvider {...methods}>
        <form
          name="dashboard-user-add"
          data-testid="dashboard-user-add"
          onSubmit={methods.handleSubmit(onSubmit)}
          role="form"
        >
          <div style={{ display: "flex", flexDirection: "row" }}>
            <div className="field mb-2 mr-2">
              <UIFormInput
                isReactHookForm
                required
                id="dashboard-user-add-username"
                data-testid="dashboard-user-add-username"
                name="username"
                label="Net ID"
                placeholder="Net ID"
              />
            </div>
            <div className="field mb-1">
              <button
                className="button is-primary"
                type="submit"
                data-testid="dashboard-user-add-submit"
              >
                Add User
              </button>
            </div>
          </div>
        </form>
      </FormProvider>
      <div className="table-container">
        <table
          className="table is-striped is-fullwidth"
          data-testid="users-dashboard-table"
        >
          <thead>
            <tr>
              {colHeaders.map((col) => (
                <th key={col}>{col}</th>
              ))}
              <th></th>
            </tr>
          </thead>
          <tbody data-testid="users-table-body">
            {users.map((record) => {
              const {
                username = "",
                displayName = "",
                email = "",
                role = "",
              } = record;

              return (
                <tr key={username} data-testid="user-row">
                  <td>{username}</td>
                  <td>{displayName}</td>
                  <td>{email}</td>
                  <td className="has-text-right is-right mb-0">
                    <div className="field is-grouped">
                      <select
                        data-testid={`user-role-select-${username}`}
                        className="select is-small is-outlined"
                        value={role.toUpperCase()}
                        onChange={(e) => handleRoleSelect(record, e.target.value)}
                      >
                        {roles.reverse().map((r) => {
                          return (
                            <option
                              key={r.toUpperCase()}
                              value={r.toUpperCase()}
                            >
                              {r}
                            </option>
                          );
                        })}
                      </select>
                      &nbsp;
                      <button
                        className="button is-small is-outlined"
                        onClick={(e) => handleRoleSelect(record, null)}
                        data-testid={`remove-user-${username}`}
                      >
                        <IconTrashCan />
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </React.Fragment>
  );
}