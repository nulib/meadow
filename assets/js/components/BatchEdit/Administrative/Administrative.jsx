import React, { useState } from "react";
import { useForm, FormProvider } from "react-hook-form";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import BatchEditAdministrativeProjectMetadata from "./ProjectMetadata";
import BatchEditAdministrativeGeneral from "./General";
import UIAccordion from "../../UI/Accordion";
import BatchEditConfirmation from "@js/components/BatchEdit/Confirmation";
import {
  useBatchDispatch,
  useBatchState,
} from "../../../context/batch-edit-context";
import { getBatchMultiValueDataFromForm } from "../../../services/metadata";
import { Button } from "@nulib/admin-react-components";
import BatchEditCollection from "@js/components/BatchEdit/Administrative/Collection";
import BatchEditPublish from "@js/components/BatchEdit/Publish";

const BatchEditAdministrative = () => {
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);
  const [batchAdds, setBatchAdds] = useState({ administrativeMetadata: {} });
  const [batchReplaces, setBatchReplaces] = useState({
    administrativeMetadata: {},
  });
  const [batchVisibility, setBatchVisibility] = useState({});
  const batchDispatch = useBatchDispatch();
  const [batchCollection, setBatchCollection] = useState({});
  const [batchPublish, setBatchPublish] = useState({
    publish: false,
    unpublish: false,
  });

  // Grab batch search data from Context
  const batchState = useBatchState();

  const numberOfResults = batchState.resultStats
    ? batchState.resultStats.numberOfResults
    : 0;

  // Initialize React hook form
  const methods = useForm();

  const onCloseModal = () => {
    setIsConfirmModalOpen(false);
  };

  // Handle Administrative tab form submit (Core and Descriptive metadata)
  const onSubmit = (data) => {
    console.log("data", data);

    let currentFormValues = methods.getValues();
    console.log("currentFormValues", currentFormValues);
    let addItems = {};
    let replaceItems = {};
    let multiValues = {};

    // Update single value items
    ["preservationLevel", "status", "libraryUnit"].forEach((item) => {
      if (currentFormValues[item]) {
        replaceItems[item] = JSON.parse(currentFormValues[item]);
      }
    });
    if (currentFormValues.projectCycle) {
      replaceItems.projectCycle = currentFormValues.projectCycle;
    }

    // Update non-controlled term multi-value items
    multiValues = getBatchMultiValueDataFromForm(currentFormValues);

    setBatchAdds({
      administrativeMetadata: { ...addItems, ...multiValues.add },
    });

    setBatchReplaces({
      administrativeMetadata: { ...replaceItems, ...multiValues.replace },
      ...((batchPublish.publish || batchPublish.unpublish) && {
        published: { ...batchPublish },
      }),
    });

    Object.keys(currentFormValues["collection"]).length > 0
      ? setBatchCollection(JSON.parse(currentFormValues["collection"]))
      : setBatchCollection({});

    Object.keys(currentFormValues["visibility"]).length > 0
      ? setBatchVisibility(JSON.parse(currentFormValues["visibility"]))
      : setBatchVisibility({});

    setIsConfirmModalOpen(true);
  };

  const handleFormReset = () => {
    methods.reset();
    batchDispatch({ type: "clearRemoveItems" });
  };

  return (
    <FormProvider {...methods}>
      <form
        name="batch-edit-administrative-form"
        data-testid="batch-edit-administrative-form"
        onSubmit={methods.handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader
          title="Administrative Metadata"
          data-testid="batch-edit-administrative-sticky-header"
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
            <UIAccordion
              testid="project-status-metadata-wrapper"
              title="General"
            >
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
      </form>

      {isConfirmModalOpen ? (
        <BatchEditConfirmation
          batchEditType="administrativeMetadata"
          batchAdds={batchAdds}
          batchReplaces={batchReplaces}
          batchVisibility={batchVisibility}
          batchCollection={batchCollection}
          filteredQuery={JSON.stringify(batchState.filteredQuery)}
          handleClose={onCloseModal}
          handleFormReset={handleFormReset}
          isConfirmModalOpen={isConfirmModalOpen}
          numberOfResults={numberOfResults}
        />
      ) : null}
    </FormProvider>
  );
};

export default BatchEditAdministrative;
