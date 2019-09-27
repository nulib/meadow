import React, { useContext } from "react";
import { AuthContext } from "../components/Auth/Auth";
import { Redirect } from "react-router-dom";

const ScreensLogin = () => {
  const me = useContext(AuthContext);

  const redirectToLogin = () => {
    location.pathname = `/auth/openam`;
  };

  if (me) return <Redirect to="/" />;

  return (
    <div className="container w-full flex justify-center">
      <div className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 mt-32 text-center max-w-sm">
        <h1 className="text-gray-600 mb-4">Please login via SSO</h1>
        <button className="btn btn-primary" onClick={redirectToLogin}>
          Login
        </button>
      </div>
    </div>
  );
};

export default ScreensLogin;
