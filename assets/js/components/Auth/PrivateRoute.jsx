import React, { useContext } from "react";
import { AuthContext } from "./Auth";
import { Route, Redirect } from "react-router-dom";
import Layout from "../../screens/Layout";

const PrivateRoute = ({ component: Component, ...rest }) => {
  const me = useContext(AuthContext);

  return (
    <Route
      {...rest}
      render={props =>
        me ? (
          <Layout>
            <Component {...props} />
          </Layout>
        ) : (
          <Redirect
            to={{
              pathname: "/login",
              state: { from: props.location }
            }}
          />
        )
      }
    />
  );
};

export default PrivateRoute;
