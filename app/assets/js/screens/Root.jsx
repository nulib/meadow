import { BrowserRouter, Route, Switch } from "react-router-dom";
import {
  ELASTICSEARCH_PROXY_ENDPOINT,
  ELASTICSEARCH_WORK_INDEX,
} from "../services/elasticsearch";

import { AuthProvider } from "../components/Auth/Auth";
import { BatchProvider } from "../context/batch-edit-context";
import Home from "./Home/Home";
import Login from "./Login";
import NotFound from "./404";
import PrivateRoute from "../components/Auth/PrivateRoute";
import { REACTIVE_SEARCH_THEME } from "../services/reactive-search";
import React from "react";
import { ReactiveBase } from "@appbaseio/reactivesearch";
import ScreensBatchEdit from "./BatchEdit/BatchEdit";
import ScreensCollection from "./Collection/Collection";
import ScreensCollectionForm from "./Collection/Form";
import ScreensCollectionList from "./Collection/List";
import ScreensDashboardsAnalytics from "@js/screens/Dashboards/Analytics/Analytics";
import ScreensDashboardsBatchEditDetails from "@js/screens/Dashboards/BatchEdit/Details";
import ScreensDashboardsBatchEditList from "@js/screens/Dashboards/BatchEdit/List";
import ScreensDashboardsCsvDetails from "@js/screens/Dashboards/Csv/Details";
import ScreensDashboardsCsvList from "@js/screens/Dashboards/Csv/List";
import ScreensDashboardsLocalAuthoritiesList from "@js/screens/Dashboards/LocalAuthorities/List";
import ScreensDashboardsPreservationChecksList from "@js/screens/Dashboards/PreservationChecks/List";
import ScreensIngestSheet from "./IngestSheet/IngestSheet";
import ScreensProject from "./Project/Project";
import ScreensProjectList from "./Project/List";
import ScreensSearch from "./Search/Search";
import ScreensWork from "./Work/Work";
import ScrollToTop from "../components/ScrollToTop";

export default class Root extends React.Component {
  render() {
    return (
      <ReactiveBase
        app={ELASTICSEARCH_WORK_INDEX}
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
