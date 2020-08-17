import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import BatchEditAboutUncontrolledMetadata from "./UncontrolledMetadata";
import BatchEditAboutPhysicalMetadata from "./PhysicalMetadata";
import BatchEditAboutRightsMetadata from "./RightsMetadata";
import BatchEditAboutIdentifiersMetadata from "./IdentifiersMetadata";
import UIAccordion from "../../UI/Accordion";
import BatchEditConfirmation from "./Confirmation";
import BatchEditAboutModalRemove from "../ModalRemove";
import {
  useBatchDispatch,
  useBatchState,
} from "../../../context/batch-edit-context";
import {
  CONTROLLED_METADATA,
  prepControlledTermInput,
  prepFacetKey,
} from "../../../services/metadata";

const BatchEditAbout = () => {
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);
  const [batchAdds, setBatchAdds] = useState({ descriptiveMetadata: {} });
  const [batchDeletes, setBatchDeletes] = useState({});

  const batchDispatch = useBatchDispatch();

  // Grab batch search data from Context
  const batchState = useBatchState();

  const numberOfResults = batchState.resultStats
    ? batchState.resultStats.numberOfResults
    : 0;

  // Initialize React hook form
  const {
    register,
    handleSubmit,
    errors,
    control,
    getValues,
    formState,
    reset,
  } = useForm({
    defaultValues: {},
  });

  const onCloseModal = () => {
    setIsConfirmModalOpen(false);
  };

  // Handle About tab form submit (Core and Descriptive metadata)
  const onSubmit = (data) => {
    // "data" here returns everything (which was set above in the useEffect()),
    // including fields that are either outdated or which no values were ever registered
    // with React Hook Form's register().   So, we'll use getValues() to get the real data
    // updated.

    let currentFormValues = getValues();
    console.log("currentFormValues :>> ", currentFormValues);
    let addItems = {};
    let deleteReadyItems = {};

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

    setBatchAdds({ descriptiveMetadata: addItems });
    setBatchDeletes(deleteReadyItems);
    setIsConfirmModalOpen(true);
  };

  const handleFormReset = () => {
    reset();
    batchDispatch({ type: "clearRemoveItems" });
  };

  return (
    <div>
      <form
        name="batch-edit-about-form"
        data-testid="batch-edit-about-form"
        onSubmit={handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader
          title="Core and Descriptive Metadata"
          data-testid="batch-edit-about-sticky-header"
        >
          <>
            <button
              type="submit"
              className="button is-primary"
              data-testid="save-button"
            >
              Save Data for {numberOfResults} Items
            </button>
            <button
              type="button"
              className="button is-text"
              data-testid="cancel-button"
              onClick={() => reset()}
            >
              Clear Form
            </button>
          </>
        </UITabsStickyHeader>

        <p
          className="notification is-warning mt-5"
          data-testid="batch-edit-warning-notification"
        >
          <span className="icon">
            <FontAwesomeIcon icon="exclamation-triangle" />
          </span>
          You are editing {numberOfResults} items. Proceed with caution.
        </p>

        <UIAccordion testid="core-metadata-wrapper" title="Core Metadata">
          <BatchEditAboutCoreMetadata
            errors={errors}
            control={control}
            register={register}
          />
        </UIAccordion>

        <UIAccordion
          testid="controlled-metadata-wrapper"
          title="Creator and Subject Information"
        >
          <BatchEditAboutControlledMetadata
            control={control}
            errors={errors}
            register={register}
          />
        </UIAccordion>

        <UIAccordion
          testid="uncontrolled-metadata-wrapper"
          title="Description Information"
        >
          <BatchEditAboutUncontrolledMetadata
            control={control}
            errors={errors}
            register={register}
          />
        </UIAccordion>
        <UIAccordion
          testid="physical-metadata-wrapper"
          title="Physical Objects Information"
        >
          <BatchEditAboutPhysicalMetadata
            control={control}
            errors={errors}
            register={register}
          />
        </UIAccordion>

        <UIAccordion
          testid="rights-metadata-wrapper"
          title="Rights Information"
        >
          <BatchEditAboutRightsMetadata
            control={control}
            errors={errors}
            register={register}
          />
        </UIAccordion>

        <UIAccordion
          testid="identifiers-metadata-wrapper"
          title="Identifiers and Relationship Information"
        >
          <BatchEditAboutIdentifiersMetadata
            control={control}
            errors={errors}
            register={register}
          />
        </UIAccordion>
      </form>

      {isConfirmModalOpen ? (
        <BatchEditConfirmation
          batchAdds={batchAdds}
          batchDeletes={batchDeletes}
          filteredQuery={JSON.stringify(batchState.filteredQuery)}
          handleClose={onCloseModal}
          handleFormReset={handleFormReset}
          isConfirmModalOpen={isConfirmModalOpen}
        />
      ) : null}

      <BatchEditAboutModalRemove />
    </div>
  );
};

export default BatchEditAbout;
