import React, { Component } from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import { GET_CURRENT_USER_QUERY } from "./auth.query";

function CurrentUser({ children }) {
  const { loading, error, data } = useQuery(GET_CURRENT_USER_QUERY);

  if (error) return <Error error={error} />;

  return children(data.me);
}

CurrentUser.propTypes = {
  children: PropTypes.func.isRequired
};

export default CurrentUser;
