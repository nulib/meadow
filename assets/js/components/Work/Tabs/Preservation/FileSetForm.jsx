import React from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UIFormField from "@js/components/UI/Form/Field.jsx";

function WorkTabsPreservationFileSetForm({ s3UploadLocation }) {
  return (
    <>
      {s3UploadLocation && (
        <div>
          <UIFormField label="Fileset accession number">
            <UIFormInput
              isReactHookForm
              required
              label="Fileset accession number"
              data-testid="fileset-accession-number-input"
              name="accessionNumber"
              placeholder="Fileset accession number"
            />
          </UIFormField>

          <UIFormField label="Label">
            <UIFormInput
              isReactHookForm
              required
              label="Label"
              data-testid="fileset-label-input"
              name="label"
              placeholder="Fileset label"
            />
          </UIFormField>

          <UIFormField label="Description">
            <UIFormInput
              isReactHookForm
              required
              label="Description"
              data-testid="fileset-description-input"
              name="description"
              placeholder="Description of the Fileset"
            />
          </UIFormField>
        </div>
      )}
    </>
  );
}

WorkTabsPreservationFileSetForm.propTypes = {
  s3UploadLocation: PropTypes.string,
};

export default WorkTabsPreservationFileSetForm;
