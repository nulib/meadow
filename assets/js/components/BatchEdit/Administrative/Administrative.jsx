import React, { useState } from "react";
import { useForm, FormProvider } from "react-hook-form";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import BatchEditAdministrativeProjectMetadata from "./ProjectMetadata";
import BatchEditAdministrativeProjectStatusMetadata from "./ProjectStatusMetadata";
import UIAccordion from "../../UI/Accordion";
import BatchEditConfirmation from "@js/components/BatchEdit/Administrative/Confirmation";
// import BatchEditAdministrativeModalRemove from "../ModalRemove";
import {
  useBatchDispatch,
  useBatchState,
} from "../../../context/batch-edit-context";
import {
  PROJECT_METADATA,
  getBatchMultiValueDataFromForm,
  prepControlledTermInput,
  prepFacetKey,
} from "../../../services/metadata";
import { Button } from "@nulib/admin-react-components";

const BatchEditAdministrative = () => {
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);
  const [batchAdds, setBatchAdds] = useState({ administrativeMetadata: {} });
  const [batchDeletes, setBatchDeletes] = useState({});
  const [batchReplaces, setBatchReplaces] = useState({
    administrativeMetadata: {},
  });
  const [batchVisibility, setBatchVisibility] = useState({});
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
  const { dirtyFields, touched } = methods.formState;

  const onCloseModal = () => {
    setIsConfirmModalOpen(false);
  };

  // Handle Administrative tab form submit (Core and Descriptive metadata)
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
    ["preservationLevel", "status"].forEach((item) => {
      console.log(item, currentFormValues[item]);

      if (currentFormValues[item]) {
        replaceItems[item] = JSON.parse(currentFormValues[item]);
      }
    });
    if (currentFormValues.projectCycle) {
      replaceItems.projectCycle = currentFormValues.projectCycle;
    }

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of PROJECT_METADATA) {
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

    setBatchAdds({
      administrativeMetadata: { ...addItems, ...multiValues.add },
    });
    setBatchDeletes(deleteReadyItems);

    setBatchReplaces({
      administrativeMetadata: { ...replaceItems, ...multiValues.replace },
    });

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
        name="batch-edit-about-form"
        data-testid="batch-edit-about-form"
        onSubmit={methods.handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader
          title="Administrative Metadata"
          data-testid="batch-edit-about-sticky-header"
        >
          <>
            <Button type="submit" isPrimary data-testid="save-button">
              Save Data for {numberOfResults} Items
            </Button>
            <Button
              isText
              data-testid="cancel-button"
              onClick={handleFormReset}
            >
              Clear Form
            </Button>
          </>
        </UITabsStickyHeader>

        <UIAccordion testid="project-metadata-wrapper" title="Project Metadata">
          <BatchEditAdministrativeProjectMetadata />
        </UIAccordion>

        <UIAccordion
          testid="project-status-metadata-wrapper"
          title="Project Status Metadata"
        >
          <BatchEditAdministrativeProjectStatusMetadata />
        </UIAccordion>
      </form>

      {isConfirmModalOpen ? (
        <BatchEditConfirmation
          batchAdds={batchAdds}
          batchDeletes={batchDeletes}
          batchReplaces={batchReplaces}
          batchVisibility={batchVisibility}
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
