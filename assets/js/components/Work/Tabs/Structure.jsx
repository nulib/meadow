import React, { useContext, useState } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "../../IIIF/IIIFProvider";

import useIsEditing from "../../../hooks/useIsEditing";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import { SET_WORK_IMAGE } from "../work.query";
import { toastWrapper } from "../../../services/helpers";
import WorkTabsHeader from "./Header";
import UIFormInput from "../../UI/Form/Input";
import UIFormTextarea from "../../UI/Form/Textarea";
import UIFormField from "../../UI/Form/Field";
import WorkTabsDownloadLinks from "./DownloadLinks";

const parseWorkRepresentativeImage = (work) => {
  if (!work.representativeImage) return;
  const arr = work.representativeImage.split("/");
  return arr[arr.length - 1];
};

const WorkTabsStructure = ({ work }) => {
  const [isEditing, setIsEditing] = useIsEditing();
  const [workImageFilesetId, setWorkImageFilesetId] = useState(
    parseWorkRepresentativeImage(work)
  );
  const { register, handleSubmit, errors } = useForm();
  const iiifServerUrl = useContext(IIIFContext);

  const [setWorkImage] = useMutation(SET_WORK_IMAGE, {
    onCompleted({ setWorkImage }) {
      toastWrapper("is-success", "Work image has been updated");
    },
  });

  if (!work) {
    return null;
  }

  const handleDownloadClick = (type) => {
    console.log("Download clicked and type: ", type);
  };

  const handleWorkImageChange = (id) => {
    if (id === workImageFilesetId) return;

    setWorkImageFilesetId(id === workImageFilesetId ? null : id);
    setWorkImage({ variables: { fileSetId: id, workId: work.id } });
  };

  const onSubmit = (data) => {
    // TODO : add logic to update filesets for given work.
    console.log(data);
  };

  return (
    <form name="work-structure-form" onSubmit={handleSubmit(onSubmit)}>
      <WorkTabsHeader title="Filesets">
        {!isEditing && (
          <button
            type="button"
            className="button is-primary"
            onClick={() => setIsEditing(true)}
          >
            Edit
          </button>
        )}
        {isEditing && (
          <>
            <button type="submit" className="button is-primary">
              Save
            </button>
            <button
              type="button"
              className="button is-text"
              onClick={() => setIsEditing(false)}
            >
              Cancel
            </button>
          </>
        )}
      </WorkTabsHeader>

      <div style={{ marginTop: "1rem" }}>
        {work.fileSets.map(({ id, accessionNumber, metadata }) => (
          <article key={id} className="box">
            <div className="columns">
              <div className="column is-2">
                <figure className="image">
                  <img
                    src={`${iiifServerUrl}${id}/square/500,500/0/default.jpg`}
                    placeholder="Fileset Image"
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
                      />
                      <label htmlFor={`checkbox-work-switch-${id}`}>
                        Work image
                      </label>
                    </div>

                    <WorkTabsDownloadLinks
                      handleDownloadClick={handleDownloadClick}
                    />
                  </>
                )}
              </div>
            </div>
          </article>
        ))}

        <section
          className="section has-background-dark has-text-white"
          style={{ marginTop: "1rem" }}
        >
          <h3 className="subtitle has-text-white">Download all files as zip</h3>
          <div className="columns">
            <div className="column">
              <div className="field">
                <input
                  type="radio"
                  className="is-checkradio"
                  name="downloadsize"
                  id="downloadsize1"
                />
                <label htmlFor="downloadsize1"> Full size</label>
                <input
                  type="radio"
                  className="is-checkradio"
                  name="downloadsize"
                  id="downloadsize2"
                />
                <label htmlFor="downloadsize2"> 3000x3000</label>
                <input
                  type="radio"
                  className="is-checkradio"
                  name="downloadsize"
                  id="downloadsize3"
                />
                <label htmlFor="downloadsize3"> 1000x1000</label>
              </div>
            </div>

            <div className="column buttons has-text-right">
              <button className="button">Download Tiffs</button>
              <button className="button is-primary">Download JPGs</button>
            </div>
          </div>
        </section>
      </div>
    </form>
  );
};

WorkTabsStructure.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsStructure;
