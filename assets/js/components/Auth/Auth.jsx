import React from "react";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import { GET_CURRENT_USER_QUERY } from "./auth.gql";
import Honeybadger from "@honeybadger-io/js";

export const AuthContext = React.createContext();

export const AuthProvider = ({ children }) => {
  const { loading, error, data } = useQuery(GET_CURRENT_USER_QUERY);

  if (error) return <Error error={error} />;
  if (loading) return null;

  Honeybadger.setContext({
    user_id: data.me.username,
    user_email: data.me.email,
    user_display_name: data.me.displayName,
    user_role: data.me.role,
  });

  return (
    <AuthContext.Provider value={data.me}>{children}</AuthContext.Provider>
  );
};
