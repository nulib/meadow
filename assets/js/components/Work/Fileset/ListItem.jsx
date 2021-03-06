import React, { useContext } from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import UIFormField from "@js/components/UI/Form/Field";
import WorkFilesetActionButtonsAccess from "@js/components/Work/Fileset/ActionButtons/Access";
import WorkFilesetActionButtonsAuxillary from "@js/components/Work/Fileset/ActionButtons/Auxillary";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import useFileSet from "@js/hooks/useFileSet";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";
import { Button, Tag } from "@nulib/admin-react-components";
import { IconPlay } from "@js/components/Icon";

function WorkFilesetListItem({
  fileSet,
  handleWorkImageChange,
  isEditing,
  workImageFilesetId,
}) {
  const iiifServerUrl = useContext(IIIFContext);
  const { id, coreMetadata } = fileSet;
  const dispatch = useWorkDispatch();
  const { isMedia } = useFileSet();
  const workContextState = useWorkState();

  // Helper for media type file sets
  const isCurrentStateFileSet =
    workContextState?.activeMediaFileSet?.id === fileSet?.id;

  // https://stackoverflow.com/questions/34097560/react-js-replace-img-src-onerror
  const [imgState, setImgState] = React.useState({
    errored: false, // This prevents a potential infinite loop
    src: `${iiifServerUrl}${id}/square/500,500/0/default.jpg`,
  });

  const handleError = (e) => {
    if (!imgState.errored) {
      setImgState({
        errored: true,
        src: isMedia(fileSet)
          ? "/images/video-placeholder.png"
          : "/images/placeholder.png",
      });
    }
  };

  return (
    <article className="box" data-testid="fileset-item">
      <div className="columns">
        <div className="column is-2">
          <figure className="image">
            <img
              src={imgState.src}
              placeholder="Fileset Image"
              data-testid="fileset-image"
              onError={handleError}
            />
          </figure>
          {isMedia(fileSet) && (
            <Button
              onClick={() =>
                dispatch({
                  type: "updateActiveMediaFileSet",
                  fileSet,
                })
              }
              className="is-small is-fullwidth mt-2"
            >
              <span className="icon">
                <IconPlay />
              </span>
              <span>Play</span>
            </Button>
          )}
        </div>
        <div className="column">
          {isMedia(fileSet) && isCurrentStateFileSet && (
            <span className="mb-4 is-inline-block">
              <Tag isInfo>Now Playing</Tag>
            </span>
          )}

          <UIFormField label="Label">
            {isEditing ? (
              <UIFormInput
                isReactHookForm
                required
                label="Label"
                name={`${id}.label`}
                data-testid="input-label"
                placeholder="Label"
                defaultValue={coreMetadata.label}
              />
            ) : (
              <p>{coreMetadata.label}</p>
            )}
          </UIFormField>

          <UIFormField label="Description">
            {isEditing ? (
              <UIFormTextarea
                isReactHookForm
                name={`${id}.description`}
                data-testid="textarea-metadata-description"
                defaultValue={coreMetadata.description}
                label="Description"
                rows="2"
              />
            ) : (
              <p>{coreMetadata.description}</p>
            )}
          </UIFormField>
        </div>
        <div className="column is-5 has-text-right is-clearfix">
          {!isEditing && (
            <>
              {/* Only display representative image toggle for Image file sets */}
              {/* Its assumed media files will only have placeholder thumbnails for now */}
              {!isMedia(fileSet) && (
                <AuthDisplayAuthorized>
                  <div className="field">
                    <input
                      id={`checkbox-work-switch-${id}`}
                      type="checkbox"
                      name={`checkbox-work-switch-${id}`}
                      className="switch"
                      checked={workImageFilesetId === id}
                      onChange={() => handleWorkImageChange(id)}
                      data-testid="work-image-selector"
                    />
                    <label htmlFor={`checkbox-work-switch-${id}`}>
                      Work image
                    </label>
                  </div>
                </AuthDisplayAuthorized>
              )}

              {fileSet.role.id === "A" && (
                <WorkFilesetActionButtonsAccess fileSet={fileSet} />
              )}
              {fileSet.role.id === "X" && (
                <WorkFilesetActionButtonsAuxillary fileSet={fileSet} />
              )}
              {fileSet.role.id === "S" && (
                <WorkFilesetActionButtonsSupplemental fileSet={fileSet} />
              )}
            </>
          )}
        </div>
      </div>
    </article>
  );
}

WorkFilesetListItem.propTypes = {
  fileSet: PropTypes.object,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default WorkFilesetListItem;
