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

const BatchEditAbout = ({ numberOfResults }) => {
  const [confirmationMetadata, setConfirmationMetadata] = useState();
  const [isModalOpen, setIsModalOpen] = useState(false);

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
    console.log("handleClose called");
    setIsModalOpen(false);
  };

  // Handle About tab form submit (Core and Descriptive metadata)
  const onSubmit = (data) => {
    // "data" here returns everything (which was set above in the useEffect()),
    // including fields that are either outdated or which no values were ever registered
    // with React Hook Form's register().   So, we'll use getValues() to get the real data
    // updated.
    let currentFormValues = getValues();
    console.log("currentFormValues :>> ", currentFormValues);
    setConfirmationMetadata(currentFormValues);
    setIsModalOpen(true);
  };

  return (
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
      {isModalOpen ? (
        <BatchEditConfirmation
          addMetadata={confirmationMetadata}
          isModalOpen={isModalOpen}
          handleClose={onCloseModal}
        />
      ) : null}
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

      <UIAccordion testid="rights-metadata-wrapper" title="Rights Information">
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
  );
};

BatchEditAbout.propTypes = {
  numberOfResults: PropTypes.number,
};

export default BatchEditAbout;
