import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/client";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import BatchEditDescriptiveMetadata from "./DescriptiveMetadata";
import UIError from "../../UI/Error";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const BatchEditAbout = ({ items }) => {
  // Whether box dropdowns are open or closed
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);

  const coreMetadataWrapper = css`
    visibility: ${showCoreMetadata ? "visible" : "hidden"};
    height: ${showCoreMetadata ? "auto" : "0"};
  `;

  const descriptiveMetadataWrapper = css`
    visibility: ${showDescriptiveMetadata ? "visible" : "hidden"};
    height: ${showDescriptiveMetadata ? "auto" : "0"};
  `;

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

      <p
        className="notification is-warning mt-5"
        data-testid="batch-edit-warning-notification"
      >
        <span className="icon">
          <FontAwesomeIcon icon="exclamation-triangle" />
        </span>
        You are editing {items.length} items. Proceed with caution.
      </p>

      <div className="box is-relative mt-4" data-testid="core-metadata-wrapper">
        <h2 className="title is-size-5">
          Core Metadata{" "}
          <a onClick={() => setShowCoreMetadata(!showCoreMetadata)}>
            <FontAwesomeIcon
              icon={showCoreMetadata ? "chevron-down" : "chevron-right"}
            />
          </a>
        </h2>
        <div css={coreMetadataWrapper}>
          <BatchEditAboutCoreMetadata errors={errors} register={register} />
        </div>
      </div>

      <div
        className="box is-relative"
        data-testid="descriptive-metadata-wrapper"
      >
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
        <div css={descriptiveMetadataWrapper}>
          <BatchEditDescriptiveMetadata
            control={control}
            errors={errors}
            register={register}
          />
        </div>
      </div>
    </form>
  );
};

BatchEditAbout.propTypes = {
  items: PropTypes.array,
};

export default BatchEditAbout;
