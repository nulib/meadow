import React, { useContext } from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import UIFormField from "@js/components/UI/Form/Field";
import WorkTabsDownloadLinks from "@js/components/Work/Tabs/DownloadLinks";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";

function Filesets({
  filesets,
  handleDownloadClick,
  isEditing,
  workImageFilesetId,
}) {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <div data-testid="fileset-list" className="mb-5">
      {filesets.map(({ id, accessionNumber, metadata }) => (
        <article key={id} className="box" data-testid="fileset-item">
          <div className="columns">
            <div className="column is-2">
              <figure className="image">
                <img
                  src={`${iiifServerUrl}${id}/square/500,500/0/default.jpg`}
                  placeholder="Fileset Image"
                  data-testid="fileset-image"
                />
              </figure>
            </div>
            <div className="column content">
              <p>
                <span className="tag is-dark">
                  Accession Number: {accessionNumber}
                </span>
              </p>

              <UIFormField label="Label">
                {isEditing ? (
                  <UIFormInput
                    register={register}
                    required
                    label="Label"
                    name={`label-${id}`}
                    data-testid="input-label"
                    placeholder="Label"
                    errors={errors}
                    defaultValue={metadata.label}
                  />
                ) : (
                  <p>{metadata.label}</p>
                )}
              </UIFormField>

              <UIFormField label="Description">
                {isEditing ? (
                  <UIFormTextarea
                    register={register}
                    name={`metadataDescription-${id}`}
                    data-testid="textarea-metadata-description"
                    defaultValue={metadata.description}
                    label="Description"
                  />
                ) : (
                  <p>{metadata.description}</p>
                )}
              </UIFormField>
            </div>
            <div className="column is-3 has-text-right is-clearfix">
              {!isEditing && (
                <>
                  <div className="field">
                    <input
                      id={`checkbox-work-switch-${id}`}
                      type="checkbox"
                      name={`checkbox-work-switch-${id}`}
                      className="switch"
                      checked={workImageFilesetId === id}
                      onChange={(e) => handleWorkImageChange(id)}
                      data-testid="work-image-selector"
                    />
                    <label htmlFor={`checkbox-work-switch-${id}`}>
                      Work image
                    </label>
                  </div>

                  <WorkTabsDownloadLinks
                    handleDownloadClick={handleDownloadClick}
                    filesetId={id}
                  />
                </>
              )}
            </div>
          </div>
        </article>
      ))}
    </div>
  );
}

Filesets.propTypes = {
  filesets: PropTypes.array,
  handleDownloadClick: PropTypes.func,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default Filesets;
