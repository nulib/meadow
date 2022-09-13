import React from "react";
import Layout from "@js/screens/Layout";
import { Breadcrumbs, PageTitle } from "@js/components/UI/UI";
import ColorExperiment from "@js/components/Search/ColorExperiment";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { IconCheck } from "@js/components/Icon";
import IconText from "@js/components/UI/IconText";
import useGTM from "@js/hooks/useGTM";

function ScreensColorExperiment(props) {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Color Experiment" });
  }, []);

  return (
    <Layout>
      <section className="section" data-testid="color-experiment-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Search",
                isActive: false,
              },
              {
                label: "Color Experiment",
                route: "/search/color-experiment",
                isActive: true,
              },
            ]}
          />
          <PageTitle data-testid="color-experiment-title">
            <IconText icon={<IconCheck />}>Color Experiment</IconText>
          </PageTitle>
          <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
            <ColorExperiment />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensColorExperiment.propTypes = {};

export default ScreensColorExperiment;
