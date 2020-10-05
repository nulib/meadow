import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Draggable } from "react-beautiful-dnd";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import UIFormField from "@js/components/UI/Form/Field";
import WorkTabsDownloadLinks from "@js/components/Work/Tabs/DownloadLinks";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";

function WorkTabsStructureFileset({
  fileset,
  handleDownloadClick,
  handleWorkImageChange,
  index,
  isEditing,
  workImageFilesetId,
}) {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <Draggable draggableId={fileset.id} index={index}>
      {(provided) => (
        <article
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          className="box"
          data-testid="fileset-item"
        >
          <div className="columns">
            <div className="column is-2">
              <figure className="image">
                <img
                  src={`${iiifServerUrl}${fileset.id}/square/500,500/0/default.jpg`}
                  placeholder="Fileset Image"
                  data-testid="fileset-image"
                />
              </figure>
            </div>
            <div className="column content">
              <p>
                <span className="tag is-dark">
                  Accession Number: {fileset.accessionNumber}
                </span>
              </p>

              <UIFormField label="Label">
                {isEditing ? (
                  <UIFormInput
                    isReactHookForm
                    required
                    label="Label"
                    name={`label-${fileset.id}`}
                    data-testid="input-label"
                    placeholder="Label"
                    defaultValue={fileset.metadata.label}
                  />
                ) : (
                  <p>{fileset.metadata.label}</p>
                )}
              </UIFormField>

              <UIFormField label="Description">
                {isEditing ? (
                  <UIFormTextarea
                    isReactHookForm
                    name={`metadataDescription-${fileset.id}`}
                    data-testid="textarea-metadata-description"
                    defaultValue={fileset.metadata.description}
                    label="Description"
                  />
                ) : (
                  <p>{fileset.metadata.description}</p>
                )}
              </UIFormField>
            </div>
            <div className="column is-3 has-text-right is-clearfix">
              {!isEditing && (
                <>
                  <div className="field">
                    <input
                      id={`checkbox-work-switch-${fileset.id}`}
                      type="checkbox"
                      name={`checkbox-work-switch-${fileset.id}`}
                      className="switch"
                      checked={workImageFilesetId === fileset.id}
                      onChange={(e) => handleWorkImageChange(id)}
                      data-testid="work-image-selector"
                    />
                    <label htmlFor={`checkbox-work-switch-${fileset.id}`}>
                      Work image
                    </label>
                  </div>

                  <WorkTabsDownloadLinks
                    handleDownloadClick={handleDownloadClick}
                    filesetId={fileset.id}
                  />
                </>
              )}
            </div>
          </div>
        </article>
      )}
    </Draggable>
  );
}

WorkTabsStructureFileset.propTypes = {
  fileset: PropTypes.object,
  handleDownloadClick: PropTypes.func,
  handleWorkImageChange: PropTypes.func,
  index: PropTypes.number,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default WorkTabsStructureFileset;
