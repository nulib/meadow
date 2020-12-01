import React from "react";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import { GET_CURRENT_USER_QUERY } from "./auth.gql";

export const AuthContext = React.createContext();

export const useAuthState = () => {
  const context = React.useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuthState must be used within AuthProvider ");
  }

  return context;
};

export const AuthProvider = ({ children }) => {
  const { loading, error, data } = useQuery(GET_CURRENT_USER_QUERY);

  if (error) return <Error error={error} />;
  if (loading) return null;

  return (
    <AuthContext.Provider value={data.me}>{children}</AuthContext.Provider>
  );
};
