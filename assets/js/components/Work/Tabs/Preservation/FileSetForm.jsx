import React from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormSelect from "@js/components/UI/Form/Select.jsx";
import { FILE_SET_ROLES } from "@js/services/global-vars";
import Error from "@js/components/UI/Error";

function WorkTabsPreservationFileSetForm({ s3UploadLocation }) {
  return (
    <>
      {s3UploadLocation && (
        <div>
          <UIFormField label="Accession number">
            <UIFormInput
              isReactHookForm
              required
              label="Accession number"
              data-testid="fileset-accession-number-input"
              name="accessionNumber"
              placeholder="accession number"
            />
          </UIFormField>

          <UIFormField label="Label">
            <UIFormInput
              isReactHookForm
              required
              label="FileSet label"
              data-testid="fileset-label-input"
              name="label"
              placeholder="Fileset label"
            />
          </UIFormField>

          <UIFormField label="Description">
            <UIFormInput
              isReactHookForm
              required
              label="FileSet description"
              data-testid="fileset-description-input"
              name="description"
              placeholder="Description of the Fileset"
            />
          </UIFormField>

          <UIFormField label="Role">
            <UIFormSelect
              isReactHookForm
              name="role"
              label="Fileset Role"
              options={FILE_SET_ROLES}
              data-testid="fileset-role-input"
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
