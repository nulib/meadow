import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

import Header from "../components/UI/Header";
import ScreensProjectList from "./Project/List";
import ScreensProjectForm from "./Project/Form";
import Project from "./Project/Project";
import Home from "./Home/Home";
import NotFoundPage from "./404";
import ScreensInventorySheet from "./InventorySheet/InventorySheet";
import ScreensInventorySheetForm from "./InventorySheet/Form";
import Layout from "./Layout";
import RequireSignIn from "../components/Auth/RequireSignIn";

export default class Root extends React.Component {
  render() {
    return (
      <>
        <BrowserRouter>
          <Header />
          <ToastContainer
            position="top-center"
            hideProgressBar
            autoClose={7000}
          />
          <RequireSignIn>
            <Layout>
              <Switch>
                <Route
                  exact
                  path="/project/list"
                  component={ScreensProjectList}
                />
                <Route
                  exact
                  path="/project/create"
                  component={ScreensProjectForm}
                />
                <Route
                  exact
                  path="/project/:id/inventory-sheet/upload"
                  component={ScreensInventorySheetForm}
                />
                <Route
                  exact
                  path="/project/:id/inventory-sheet/:inventorySheetId"
                  component={ScreensInventorySheet}
                />
                <Route exact path="/project/:id" component={Project} />
                <Route exact path="/" component={Home} />
                <Route component={NotFoundPage} />
              </Switch>
            </Layout>
          </RequireSignIn>
        </BrowserRouter>
      </>
    );
  }
}
