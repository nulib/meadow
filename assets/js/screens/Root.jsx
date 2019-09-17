import React from "react";
import { BrowserRouter, Route, Switch, Redirect } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

import { AuthProvider } from "../components/Auth/Auth";
import Header from "../components/UI/Header/Header";
import ScreensProjectList from "./Project/List";
import ScreensProjectForm from "./Project/Form";
import Project from "./Project/Project";
import Home from "./Home/Home";
import NotFoundPage from "./404";
import ScreensInventorySheet from "./InventorySheet/InventorySheet";
import ScreensInventorySheetForm from "./InventorySheet/Form";
import Login from "./Login";
import PrivateRoute from "../components/Auth/PrivateRoute";

export default class Root extends React.Component {
  render() {
    return (
      <AuthProvider>
        <BrowserRouter>
          <Header />
          <ToastContainer
            position="top-center"
            hideProgressBar
            autoClose={7000}
          />

          <Switch>
            <Route exact path="/login" component={Login} />
            <PrivateRoute
              exact
              path="/project/list"
              component={ScreensProjectList}
            />
            <PrivateRoute
              exact
              path="/project/create"
              component={ScreensProjectForm}
            />
            <PrivateRoute
              exact
              path="/project/:id/inventory-sheet/upload"
              component={ScreensInventorySheetForm}
            />
            <PrivateRoute
              exact
              path="/project/:id/inventory-sheet/:inventorySheetId"
              component={ScreensInventorySheet}
            />
            <PrivateRoute exact path="/project/:id" component={Project} />
            <PrivateRoute exact path="/" component={Home} />
            <PrivateRoute component={NotFoundPage} />
          </Switch>
        </BrowserRouter>
      </AuthProvider>
    );
  }
}
