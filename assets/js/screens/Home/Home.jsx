import React, { useContext } from "react";
import { AuthContext } from "../../components/Auth/Auth";
import Layout from "../Layout";
import UIGenericHero from "../../components/UI/GenericHero";

const ScreensHome = () => {
  const me = useContext(AuthContext);

  return (
    <Layout>
      <UIGenericHero />
      <div className="section">
        <div className="container">
          <p>Home screen content here</p>
        </div>
      </div>
    </Layout>
  );
};

export default ScreensHome;
