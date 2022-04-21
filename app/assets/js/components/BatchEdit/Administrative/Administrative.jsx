import React from "react";
import PropTypes from "prop-types";
import BatchEditAdministrativeProjectMetadata from "./ProjectMetadata";
import BatchEditAdministrativeGeneral from "./General";
import UIAccordion from "@js/components/UI/Accordion";
import BatchEditCollection from "@js/components/BatchEdit/Administrative/Collection";
import BatchEditPublish from "@js/components/BatchEdit/Publish";

const BatchEditAdministrative = ({ batchPublish, setBatchPublish }) => {
  return (
    <div data-testid="batch-edit-administrative-tab-wrapper">
      <div className="columns">
        <div className="column">
          <div
            className="box content mt-4"
            data-testid="batch-collection-wrapper"
          >
            <h3>Collections</h3>
            <BatchEditCollection />
          </div>
          <UIAccordion
            className="column"
            testid="publish-wrapper"
            title="Publish"
          >
            <BatchEditPublish
              batchPublish={batchPublish}
              setBatchPublish={setBatchPublish}
            />
          </UIAccordion>
          <UIAccordion testid="project-status-metadata-wrapper" title="General">
            <BatchEditAdministrativeGeneral />
          </UIAccordion>
        </div>

        <div className="column">
          <UIAccordion
            testid="project-metadata-wrapper"
            title="Project Metadata"
          >
            <BatchEditAdministrativeProjectMetadata />
          </UIAccordion>
        </div>
      </div>
    </div>
  );
};

BatchEditAdministrative.propTypes = {
  batchPublish: PropTypes.object,
  setBatchPublish: PropTypes.func,
};

export default BatchEditAdministrative;
