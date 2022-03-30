import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";
import { AuthProvider } from "../components/Auth/Auth";
import ScreensColorExperiment from "./Search/ColorExperiment";
import ScreensDashboardsBatchEditList from "@js/screens/Dashboards/BatchEdit/List";
import ScreensDashboardsPreservationChecksList from "@js/screens/Dashboards/PreservationChecks/List";
import ScreensDashboardsBatchEditDetails from "@js/screens/Dashboards/BatchEdit/Details";
import ScreensDashboardsLocalAuthoritiesList from "@js/screens/Dashboards/LocalAuthorities/List";
import ScreensDashboardsCsvList from "@js/screens/Dashboards/Csv/List";
import ScreensDashboardsCsvDetails from "@js/screens/Dashboards/Csv/Details";
import ScreensDashboardsAnalytics from "@js/screens/Dashboards/Analytics/Analytics";
import ScreensProjectList from "./Project/List";
import ScreensProject from "./Project/Project";
import Home from "./Home/Home";
import NotFound from "./404";
import ScreensIngestSheet from "./IngestSheet/IngestSheet";
import ScreensWork from "./Work/Work";
import ScreensSearch from "./Search/Search";
import ScreensCollectionList from "./Collection/List";
import ScreensCollection from "./Collection/Collection";
import ScreensCollectionForm from "./Collection/Form";
import ScreensBatchEdit from "./BatchEdit/BatchEdit";
import Login from "./Login";
import PrivateRoute from "../components/Auth/PrivateRoute";
import ScrollToTop from "../components/ScrollToTop";
import { ReactiveBase } from "@appbaseio/reactivesearch";
import {
  ELASTICSEARCH_PROXY_ENDPOINT,
  ELASTICSEARCH_INDEX_NAME,
} from "../services/elasticsearch";
import { REACTIVE_SEARCH_THEME } from "../services/reactive-search";
import { BatchProvider } from "../context/batch-edit-context";

export default class Root extends React.Component {
  render() {
    return (
      <ReactiveBase
        app={ELASTICSEARCH_INDEX_NAME}
        theme={REACTIVE_SEARCH_THEME}
        url={ELASTICSEARCH_PROXY_ENDPOINT}
      >
        <AuthProvider>
          <BatchProvider>
            <BrowserRouter>
              <ScrollToTop />
              <Switch>
                <Route exact path="/login" component={Login} />
                <PrivateRoute
                  exact
                  path="/search/color-experiment"
                  component={ScreensColorExperiment}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/preservation-checks"
                  component={ScreensDashboardsPreservationChecksList}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/batch-edit"
                  component={ScreensDashboardsBatchEditList}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/batch-edit/:id"
                  component={ScreensDashboardsBatchEditDetails}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/nul-local-authorities"
                  component={ScreensDashboardsLocalAuthoritiesList}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/csv-metadata-update"
                  component={ScreensDashboardsCsvList}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/csv-metadata-update/:id"
                  component={ScreensDashboardsCsvDetails}
                />
                <PrivateRoute
                  exact
                  path="/dashboards/analytics"
                  component={ScreensDashboardsAnalytics}
                />
                <PrivateRoute
                  exact
                  path="/project/list"
                  component={ScreensProjectList}
                />
                <PrivateRoute
                  exact
                  path="/project/:id/ingest-sheet/:sheetId"
                  component={ScreensIngestSheet}
                />
                <PrivateRoute
                  exact
                  path="/project/:id"
                  component={ScreensProject}
                />
                <PrivateRoute
                  exact
                  path="/work/:id/:multi?/:counter?"
                  component={ScreensWork}
                />
                <PrivateRoute
                  exact
                  path="/collection/list"
                  component={ScreensCollectionList}
                />
                <PrivateRoute
                  exact
                  path="/collection/form/:id?"
                  component={ScreensCollectionForm}
                />
                <PrivateRoute
                  exact
                  path="/collection/:id"
                  component={ScreensCollection}
                />
                <PrivateRoute exact path="/search" component={ScreensSearch} />
                <PrivateRoute
                  exact
                  path="/batch-edit"
                  component={ScreensBatchEdit}
                />
                <PrivateRoute exact path="/" component={Home} />
                <PrivateRoute component={NotFound} />
              </Switch>
            </BrowserRouter>
          </BatchProvider>
        </AuthProvider>
      </ReactiveBase>
    );
  }
}
