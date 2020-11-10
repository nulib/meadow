import React, { useState } from "react";
import PropTypes from "prop-types";
import { useForm, FormProvider } from "react-hook-form";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import BatchEditAboutUncontrolledMetadata from "./UncontrolledMetadata";
import BatchEditAboutPhysicalMetadata from "./PhysicalMetadata";
import BatchEditAboutRightsMetadata from "./RightsMetadata";
import BatchEditAboutIdentifiersMetadata from "./IdentifiersMetadata";
import UIAccordion from "../../UI/Accordion";
import BatchEditConfirmation from "@js/components/BatchEdit/Confirmation";
import BatchEditAboutModalRemove from "../ModalRemove";
import {
  useBatchDispatch,
  useBatchState,
} from "../../../context/batch-edit-context";
import {
  CONTROLLED_METADATA,
  getBatchMultiValueDataFromForm,
  prepControlledTermInput,
  prepFacetKey,
} from "../../../services/metadata";
import { Button } from "@nulib/admin-react-components";
import BatchEditPublish from "@js/components/BatchEdit/Publish";

const BatchEditAbout = () => {
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);
  const [batchAdds, setBatchAdds] = useState({ descriptiveMetadata: {} });
  const [batchDeletes, setBatchDeletes] = useState({});
  const [batchReplaces, setBatchReplaces] = useState({
    descriptiveMetadata: {},
  });
  const [batchCollection, setBatchCollection] = useState({});
  const [batchPublish, setBatchPublish] = useState({
    publish: false,
    unpublish: false,
  });

  const batchDispatch = useBatchDispatch();

  // Grab batch search data from Context
  const batchState = useBatchState();

  const numberOfResults = batchState.resultStats
    ? batchState.resultStats.numberOfResults
    : 0;

  // Initialize React hook form
  const methods = useForm({
    defaultValues: {},
  });

  const onCloseModal = () => {
    setIsConfirmModalOpen(false);
  };

  // Handle About tab form submit (Core and Descriptive metadata)
  const onSubmit = (data) => {
    console.log("data", data);

    // "data" here returns everything (which was set above in the useEffect()),
    // including fields that are either outdated or which no values were ever registered
    // with React Hook Form's register().   So, we'll use getValues() to get the real data
    // updated.

    let currentFormValues = methods.getValues();
    console.log("currentFormValues", currentFormValues);
    let addItems = {};
    let deleteReadyItems = {};
    let replaceItems = {};
    let multiValues = {};

    // Update single value items
    ["title"].forEach((item) => {
      if (currentFormValues[item]) {
        replaceItems[item] = currentFormValues[item];
      }
    });

    if (currentFormValues.rightsStatement) {
      replaceItems.rightsStatement = JSON.parse(
        currentFormValues.rightsStatement
      );
    }

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of CONTROLLED_METADATA) {
      // Include only active form additions
      if (currentFormValues[term.name]) {
        addItems[term.name] = prepControlledTermInput(
          term,
          currentFormValues[term.name],
          true
        );
      }

      // Include only active removals
      if (batchState.removeItems && batchState.removeItems[term.name]) {
        deleteReadyItems[term.name] = prepFacetKey(
          term,
          batchState.removeItems[term.name]
        );
      }
    }

    // Update non-controlled term multi-value items
    multiValues = getBatchMultiValueDataFromForm(currentFormValues);

    setBatchAdds({ descriptiveMetadata: { ...addItems, ...multiValues.add } });
    setBatchDeletes(deleteReadyItems);
    setBatchReplaces({
      descriptiveMetadata: { ...replaceItems, ...multiValues.replace },
      ...((batchPublish.publish || batchPublish.unpublish) && {
        published: { ...batchPublish },
      }),
    });

    Object.keys(currentFormValues["collection"]).length > 0
      ? setBatchCollection(JSON.parse(currentFormValues["collection"]))
      : setBatchCollection({});

    setIsConfirmModalOpen(true);
  };

  const handleFormReset = () => {
    methods.reset();
    batchDispatch({ type: "clearRemoveItems" });
  };

  return (
    <FormProvider {...methods}>
      <form
        name="batch-edit-about-form"
        data-testid="batch-edit-about-form"
        onSubmit={methods.handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader
          title="Core and Descriptive Metadata"
          data-testid="batch-edit-about-sticky-header"
        >
          <>
            <Button type="submit" isPrimary data-testid="save-button">
              Save data for {numberOfResults} items
            </Button>
            <Button
              isText
              data-testid="cancel-button"
              onClick={handleFormReset}
            >
              Clear form
            </Button>
          </>
        </UITabsStickyHeader>

        <UIAccordion testid="publish-wrapper" title="Publish">
          <BatchEditPublish
            batchPublish={batchPublish}
            setBatchPublish={setBatchPublish}
          />
        </UIAccordion>

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

        <UIAccordion
          testid="rights-metadata-wrapper"
          title="Rights Information"
        >
          <BatchEditAboutRightsMetadata />
        </UIAccordion>

        <UIAccordion
          testid="identifiers-metadata-wrapper"
          title="Identifiers and Relationship Information"
        >
          <BatchEditAboutIdentifiersMetadata />
        </UIAccordion>
      </form>

      {isConfirmModalOpen ? (
        <BatchEditConfirmation
          batchEditType="descriptiveMetadata"
          batchAdds={batchAdds}
          batchDeletes={batchDeletes}
          batchReplaces={batchReplaces}
          batchCollection={batchCollection}
          filteredQuery={JSON.stringify(batchState.filteredQuery)}
          handleClose={onCloseModal}
          handleFormReset={handleFormReset}
          isConfirmModalOpen={isConfirmModalOpen}
          numberOfResults={numberOfResults}
        />
      ) : null}

      <BatchEditAboutModalRemove />
    </FormProvider>
  );
};

export default BatchEditAbout;
