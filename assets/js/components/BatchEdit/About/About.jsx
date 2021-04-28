import React from "react";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import BatchEditAboutUncontrolledMetadata from "./UncontrolledMetadata";
import BatchEditAboutPhysicalMetadata from "./PhysicalMetadata";
import BatchEditAboutRightsMetadata from "./RightsMetadata";
import BatchEditAboutIdentifiersMetadata from "./IdentifiersMetadata";
import UIAccordion from "@js/components/UI/Accordion";

const BatchEditAbout = () => {
  return (
    <div data-testid="batch-edit-about-tab-wrapper">
      <UIAccordion testid="core-metadata-wrapper" title="Core Metadata">
        <BatchEditAboutCoreMetadata />
      </UIAccordion>

      <UIAccordion
        testid="controlled-metadata-wrapper"
        title="Creator and Subject Information"
      >
        <BatchEditAboutControlledMetadata />
      </UIAccordion>

      <UIAccordion
        testid="uncontrolled-metadata-wrapper"
        title="Description Information"
      >
        <BatchEditAboutUncontrolledMetadata />
      </UIAccordion>
      <UIAccordion
        testid="physical-metadata-wrapper"
        title="Physical Objects Information"
      >
        <BatchEditAboutPhysicalMetadata />
      </UIAccordion>

      <UIAccordion testid="rights-metadata-wrapper" title="Rights Information">
        <BatchEditAboutRightsMetadata />
      </UIAccordion>

      <UIAccordion
        testid="identifiers-metadata-wrapper"
        title="Identifiers and Relationship Information"
      >
        <BatchEditAboutIdentifiersMetadata />
      </UIAccordion>
    </div>
  );
};

export default BatchEditAbout;
