import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { useDropzone } from "react-dropzone";
import { useForm, FormProvider } from "react-hook-form";
import { IconCsv } from "@js/components/Icon";
import UIIconText from "@js/components/UI/IconText";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function DashboardsLocalAuthoritiesModalBulkAdd({
  isOpen,
  handleClose,
}) {
  const methods = useForm({
    defaultValues: {
      bulkAction: "add" // Default to bulk add
    }
  });
  const [currentFile, setCurrentFile] = React.useState();
  const [formAction, setFormAction] = React.useState("/api/authority_records/bulk_create");

  const onDrop = React.useCallback((acceptedFiles) => {
    const file = acceptedFiles[0];
    setCurrentFile(file);

    // Chrome isn't updating the file input object correctly
    // using dropzone so let's do it manually.
    const input = document.getElementById('csv-file-input');
    const fileList = new DataTransfer();
    fileList.items.add(file);
    input.files = fileList.files;
  }, []);
  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop });

  // Handle radio button change to update form action
  const handleActionChange = (e) => {
    const action = e.target.value;
    if (action === "add") {
      setFormAction("/api/authority_records/bulk_create");
    } else if (action === "update") {
      setFormAction("/api/authority_records/bulk_update");
    }
  };

  return (
    <FormProvider {...methods}>
      <form
        method="POST"
        action={formAction}
        encType="multipart/form-data"
        name="modal-nul-authority-bulk-add"
        data-testid="modal-nul-authority-bulk-add"
        className={`modal ${isOpen ? "is-active" : ""}`}
        onSubmit={() => {
          methods.reset();
          handleClose();
        }}
        role="form"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">
              Bulk Manage NUL Authority Records
            </p>
            <button
              className="delete"
              aria-label="close"
              type="button"
              onClick={handleClose}
            ></button>
          </header>
          <section className="modal-card-body">
            {/* Radio button selection for action type */}
            <div className="field">
              <label className="label">Select Action</label>
              <div className="control">
                <label className="radio mr-4">
                  <input
                    type="radio"
                    name="bulkAction"
                    value="add"
                    defaultChecked
                    onChange={handleActionChange}
                    data-testid="bulk-add-radio"
                  />
                  <span className="ml-2">Bulk Add</span>
                </label>
                {/* 
                <label className="radio">
                  <input
                    type="radio"
                    name="bulkAction"
                    value="update"
                    onChange={handleActionChange}
                    data-testid="bulk-update-radio"
                  />
                  <span className="ml-2">Bulk Update</span>
                </label>
                */}
              </div>
            </div>

            <div
              {...getRootProps()}
              className="p-6 is-clickable has-text-centered mt-4"
              css={dropZone}
            >
              <input
                {...getInputProps()}
                id="csv-file-input"
                data-testid="dropzone-input"
                name="records"
              />
              <p className="has-text-centered">
                <UIIconText
                  icon={<IconCsv className="has-text-grey" />}
                  isCentered
                >
                  {isDragActive
                    ? "Drop the file here ..."
                    : "Drag 'n' drop a file here, or click to select file"}
                </UIIconText>
              </p>
            </div>
            {currentFile && (
              <React.Fragment>
                <p className="mt-5 pb-0 mb-0 subtitle">Current file</p>
                <table className="table is-fullwidth">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Path</th>
                      <th>Size</th>
                      <th>Type</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>{currentFile.name}</td>
                      <td>{currentFile.path}</td>
                      <td>{currentFile.size}</td>
                      <td>{currentFile.type}</td>
                    </tr>
                  </tbody>
                </table>
              </React.Fragment>
            )}
          </section>
          <footer className="modal-card-foot buttons is-right">
            <Button isText onClick={handleClose} data-testid="cancel-button">
              Cancel
            </Button>
            <Button isPrimary type="submit" data-testid="submit-button">
              Upload
            </Button>
          </footer>
        </div>
      </form>
    </FormProvider>
  );
}

DashboardsLocalAuthoritiesModalBulkAdd.propTypes = {
  isOpen: PropTypes.bool,
  handleClose: PropTypes.func.isRequired,
};

export default DashboardsLocalAuthoritiesModalBulkAdd;