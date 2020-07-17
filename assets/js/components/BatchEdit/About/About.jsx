import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import BatchEditDescriptiveMetadata from "./DescriptiveMetadata";
import UIError from "../../UI/Error";

const BatchEditAbout = ({ items }) => {
  // Whether box dropdowns are open or closed
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);

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

  // Handle About tab form submit (Core and Descriptive metadata)
  const onSubmit = (data) => {
    // "data" here returns everything (which was set above in the useEffect()),
    // including fields that are either outdated or which no values were ever registered
    // with React Hook Form's register().   So, we'll use getValues() to get the real data
    // updated.
    let currentFormValues = getValues();
    console.log("currentFormValues :>> ", currentFormValues);
    toastWrapper(
      "is-success",
      "Form successfully submitted.  Check the console for form values."
    );
  };

  return (
    <form
      name="batch-edit-about-form"
      data-testid="batch-edit-about-form"
      onSubmit={handleSubmit(onSubmit)}
    >
      <UITabsStickyHeader title="Core and Descriptive Metadata">
        <>
          <button
            type="submit"
            className="button is-primary"
            data-testid="save-button"
          >
            Save Data for {items.length} Items
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

      <p className="notification is-warning mt-5">
        <span className="icon">
          <FontAwesomeIcon icon="exclamation-triangle" />
        </span>
        You are editing {items.length} items. Be careful.
      </p>

      <div className="box is-relative mt-4">
        <h2 className="title is-size-5">
          Core Metadata{" "}
          <a onClick={() => setShowCoreMetadata(!showCoreMetadata)}>
            <FontAwesomeIcon
              icon={showCoreMetadata ? "chevron-down" : "chevron-right"}
            />
          </a>
        </h2>
        <BatchEditAboutCoreMetadata
          errors={errors}
          register={register}
          showCoreMetadata={showCoreMetadata}
        />
      </div>

      <div className="box is-relative">
        <h2 className="title is-size-5">
          Descriptive Metadata{" "}
          <a
            onClick={() => setShowDescriptiveMetadata(!showDescriptiveMetadata)}
          >
            <FontAwesomeIcon
              icon={showDescriptiveMetadata ? "chevron-down" : "chevron-right"}
            />
          </a>
        </h2>
        <BatchEditDescriptiveMetadata
          control={control}
          errors={errors}
          register={register}
          showDescriptiveMetadata={showDescriptiveMetadata}
        />
      </div>
    </form>
  );
};

BatchEditAbout.propTypes = {
  items: PropTypes.array,
};

export default BatchEditAbout;
