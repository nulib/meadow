import { Button, Notification } from "@nulib/design-system";
import {
  CONTROLLED_METADATA,
  PROJECT_METADATA,
  getBatchMultiValueDataFromForm,
  parseMultiValues,
  prepControlledTermInput,
  prepFacetKey,
  prepNotes,
  prepRelatedUrl,
} from "@js/services/metadata";
import { FormProvider, useForm } from "react-hook-form";
import React, { useState } from "react";
import {
  useBatchDispatch,
  useBatchState,
} from "@js/context/batch-edit-context";

import BatchEditAbout from "./About/About";
import BatchEditAboutModalRemove from "@js/components/BatchEdit/ModalRemove";
import BatchEditAdministrative from "./Administrative/Administrative";
import BatchEditConfirmation from "@js/components/BatchEdit/Confirmation";
import { CodeListProvider } from "@js/context/code-list-context";
import { IconAlert } from "@js/components/Icon";
import UIIconText from "../UI/IconText";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";

export default function BatchEditTabs() {
  const [activeTab, setActiveTab] = useState("tab-about");
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);
  const [batchAdds, setBatchAdds] = useState({ descriptiveMetadata: {} });
  const [batchDeletes, setBatchDeletes] = useState({});
  const [batchReplaces, setBatchReplaces] = useState({
    administrativeMetadata: {},
    descriptiveMetadata: {},
  });
  const [batchVisibility, setBatchVisibility] = useState({});
  const [batchCollection, setBatchCollection] = useState({});
  const [batchPublish, setBatchPublish] = useState({
    publish: false,
    unpublish: false,
  });

  const batchDispatch = useBatchDispatch();
  const batchState = useBatchState();

  const handleTabClick = (e) => {
    setActiveTab(e.target.id);
  };

  const numberOfResults = batchState.resultStats
    ? batchState.resultStats.numberOfResults
    : 0;

  // Initialize React hook form
  const methods = useForm({
    defaultValues: {},
  });
  const hasFormErrors = Object.keys(methods.formState.errors).length > 0;

  const onCloseModal = () => {
    setIsConfirmModalOpen(false);
  };

  /**
   * Handle React Hook Form submit
   * @param {Object} data Comes from React Hook Form
   */
  const onSubmit = (data) => {
    // "data" here returns everything (which was set above in the useEffect()),
    // including fields that are either outdated or which no values were ever registered
    // with React Hook Form's register().   So, we'll use getValues() to get the real data
    // updated.

    let currentFormValues = methods.getValues();
    let addItems = { administrative: {}, descriptive: {} };
    let deleteReadyItems = {};
    let replaceItems = { administrative: {}, descriptive: {} };
    let multiValues = {};

    /**
     * Array of data for `notes` and `relatedUrl`
     */
    const preppedDataFields = [
      { name: "notes", data: prepNotes(currentFormValues.notes) },
      {
        name: "relatedUrl",
        data: prepRelatedUrl(currentFormValues.relatedUrl),
      },
    ];

    /**
     * Process each prepped data field,
     */
    preppedDataFields.forEach((field) => {
      const { name, data } = field;
      const editType = currentFormValues[`${name}--editType`];

      switch (editType) {
        case "append":
          addItems.descriptive[name] = data;
          break;
        case "delete":
          replaceItems.descriptive[name] = [];
          break;
        case "replace":
          if (data?.length > 0) replaceItems.descriptive[name] = data;
          break;
        default:
          console.error(`No known editType of: ${editType}.`);
      }
    });

    /** Handle single-value About metadata dropdown items (whose <select> value is stringified and must be parsed to get the value) */
    ["license", "rightsStatement"].forEach((item) => {
      if (currentFormValues[item]) {
        replaceItems.descriptive[item] = JSON.parse(currentFormValues[item]);
      }
    });

    ["title"].forEach((item) => {
      if (currentFormValues[item]) {
        replaceItems.descriptive[item] = currentFormValues[item];
      }
    });

    // Process Administrative metadata items
    ["preservationLevel", "libraryUnit", "status"].forEach((item) => {
      if (currentFormValues[item]) {
        replaceItems.administrative[item] = JSON.parse(currentFormValues[item]);
      }
    });
    if (currentFormValues.projectCycle) {
      replaceItems.administrative.projectCycle = currentFormValues.projectCycle;
    }
    PROJECT_METADATA.forEach((pm) => {
      if (currentFormValues[pm.name]) {
        replaceItems.administrative[pm.name] = [currentFormValues[pm.name]];
      }
    });

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of CONTROLLED_METADATA) {
      // Include only active form additions
      if (currentFormValues[term.name]) {
        addItems.descriptive[term.name] = prepControlledTermInput(
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

    // Now we need to split this up between Descriptive and Administrative
    let administrativeMultiValues = parseMultiValues(
      multiValues,
      "administrative"
    );
    let descriptiveMultiValues = parseMultiValues(multiValues, "descriptive");

    setBatchAdds({
      administrativeMetadata: {
        ...addItems.administrative,
        ...administrativeMultiValues.add,
      },
      descriptiveMetadata: {
        ...addItems.descriptive,
        ...descriptiveMultiValues.add,
      },
    });
    setBatchDeletes(deleteReadyItems);
    setBatchReplaces({
      administrativeMetadata: {
        ...replaceItems.administrative,
        ...administrativeMultiValues.replace,
      },
      ...((batchPublish.publish || batchPublish.unpublish) && {
        published: { ...batchPublish },
      }),
      descriptiveMetadata: {
        ...replaceItems.descriptive,
        ...descriptiveMultiValues.replace,
      },
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
    <CodeListProvider>
      <div className="tabs is-centered is-boxed" data-testid="batch-edit-tabs">
        <ul>
          <li className={`${activeTab === "tab-about" && "is-active"}`}>
            <a id="tab-about" data-testid="tab-about" onClick={handleTabClick}>
              About this item
            </a>
          </li>
          <li
            className={`${activeTab === "tab-administrative" && "is-active"}`}
          >
            <a
              id="tab-administrative"
              data-testid="tab-administrative"
              onClick={handleTabClick}
            >
              Administrative
            </a>
          </li>
        </ul>
      </div>
      <div className="tabs-container">
        <FormProvider {...methods}>
          {hasFormErrors && (
            <Notification isDanger>
              <UIIconText isCentered icon={<IconAlert />}>
                The following form fields have validation errors:
                {Object.keys(methods.formState.errors).map((key) => " " + key)}
              </UIIconText>
            </Notification>
          )}
          <form
            name="batch-edit-form"
            data-testid="batch-edit-form"
            onSubmit={methods.handleSubmit(onSubmit)}
          >
            <UITabsStickyHeader
              title="Batch Edit Metadata"
              data-testid="batch-edit-sticky-header"
            >
              <>
                <Button type="submit" isPrimary data-testid="save-button">
                  Save data for {numberOfResults} items
                </Button>
                <Button
                  isText
                  data-testid="clear-button"
                  onClick={handleFormReset}
                >
                  Clear form
                </Button>
              </>
            </UITabsStickyHeader>

            <div
              data-testid="tab-about-content"
              className={`${activeTab !== "tab-about" ? "is-hidden" : ""}`}
            >
              <BatchEditAbout />
            </div>
            <div
              data-testid="tab-administrative-content"
              className={`${
                activeTab !== "tab-administrative" ? "is-hidden" : ""
              }`}
            >
              <BatchEditAdministrative
                batchPublish={batchPublish}
                setBatchPublish={setBatchPublish}
              />
            </div>
          </form>
        </FormProvider>

        {/* For controlled terms - list of all possible items to remove */}
        <BatchEditAboutModalRemove />

        {isConfirmModalOpen ? (
          <BatchEditConfirmation
            batchAdds={batchAdds}
            batchDeletes={batchDeletes}
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
      </div>
    </CodeListProvider>
  );
}
