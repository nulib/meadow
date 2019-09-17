import React from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { GET_CURRENT_USER_QUERY } from "./auth.query";

export const AuthContext = React.createContext();

export const AuthProvider = ({ children }) => {
  const { loading, error, data } = useQuery(GET_CURRENT_USER_QUERY);

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  return (
    <AuthContext.Provider value={data.me}>{children}</AuthContext.Provider>
  );
};
