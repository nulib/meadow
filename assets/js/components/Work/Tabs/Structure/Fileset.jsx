import React, { useContext } from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import UIFormField from "@js/components/UI/Form/Field";
import WorkTabsDownloadLinks from "@js/components/Work/Tabs/DownloadLinks";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";

function WorkTabsStructureFileset({
  fileSet,
  handleDownloadClick,
  handleWorkImageChange,
  isEditing,
  workImageFilesetId,
}) {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <article className="box" data-testid="fileset-item">
      <div className="columns">
        <div className="column is-2">
          <figure className="image">
            <img
              src={`${iiifServerUrl}${fileSet.id}/square/500,500/0/default.jpg`}
              placeholder="Fileset Image"
              data-testid="fileset-image"
            />
          </figure>
        </div>
        <div className="column">
          <UIFormField label="Label">
            {isEditing ? (
              <UIFormInput
                isReactHookForm
                required
                label="Label"
                name={`label-${fileSet.id}`}
                data-testid="input-label"
                placeholder="Label"
                defaultValue={fileSet.metadata.label}
              />
            ) : (
              <p>{fileSet.metadata.label}</p>
            )}
          </UIFormField>

          <UIFormField label="Description">
            {isEditing ? (
              <UIFormTextarea
                isReactHookForm
                name={`metadataDescription-${fileSet.id}`}
                data-testid="textarea-metadata-description"
                defaultValue={fileSet.metadata.description}
                label="Description"
                rows="2"
              />
            ) : (
              <p>{fileSet.metadata.description}</p>
            )}
          </UIFormField>
        </div>
        <div className="column is-3 has-text-right is-clearfix">
          {!isEditing && (
            <>
              <div className="field">
                <input
                  id={`checkbox-work-switch-${fileSet.id}`}
                  type="checkbox"
                  name={`checkbox-work-switch-${fileSet.id}`}
                  className="switch"
                  checked={workImageFilesetId === fileSet.id}
                  onChange={(e) => handleWorkImageChange(id)}
                  data-testid="work-image-selector"
                />
                <label htmlFor={`checkbox-work-switch-${fileSet.id}`}>
                  Work image
                </label>
              </div>

              <WorkTabsDownloadLinks
                handleDownloadClick={handleDownloadClick}
                fileSetId={fileSet.id}
              />
            </>
          )}
        </div>
      </div>
    </article>
  );
}

WorkTabsStructureFileset.propTypes = {
  fileSet: PropTypes.object,
  handleDownloadClick: PropTypes.func,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default WorkTabsStructureFileset;
