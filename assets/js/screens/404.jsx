import React from "react";
import { useLocation } from "react-router-dom";
import Layout from "./Layout";

const NotFound = () => {
  const { state } = useLocation();
  return (
    <Layout>
      <section className="section" data-testid="notfound-hero">
        <div className="container">
          <div className="box">
            <h1 className="title">Page not found</h1>
            <p>
              {state
                ? state.message
                : "There was an error retrieving the page you requested, or the page does not exist."}
            </p>
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default NotFound;
