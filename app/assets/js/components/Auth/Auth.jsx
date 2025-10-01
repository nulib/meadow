import React from "react";
import { useQuery } from "@apollo/client/react";
import Error from "../UI/Error";
import { GET_CURRENT_USER_QUERY } from "./auth.gql";
import Honeybadger from "@honeybadger-io/js";

export const AuthContext = React.createContext();

export const AuthProvider = ({ children }) => {
  const { loading, error, data } = useQuery(GET_CURRENT_USER_QUERY);

  if (error) return <Error error={error} />;
  if (loading) return null;

  Honeybadger.setContext({
    user_id: data.me ? data.me.username : "Not logged in",
    user_email: data.me ? data.me.email : "Not logged in",
    user_display_name: data.me ? data.me.displayName : "Not logged in",
    user_role: data.me ? data.me.role : "Not logged in",
  });

  return (
    <AuthContext.Provider value={data.me}>{children}</AuthContext.Provider>
  );
};
