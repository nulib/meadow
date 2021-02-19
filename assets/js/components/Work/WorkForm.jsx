import React, { useState } from "react";
import { useMutation } from "@apollo/client";
import { CREATE_WORK } from "./work.gql.js";
import { useForm, FormProvider } from "react-hook-form";
import Error from "@js/components/UI/Error";
import Loading from "@js/components/UI/Loading";
import { toastWrapper } from "@js/services/helpers";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import { Button } from "@nulib/admin-react-components";
import { useHistory } from "react-router-dom";

const WorkForm = ({ showWorkForm, setShowWorkForm }) => {
  const [formError, setFormError] = useState();
  const methods = useForm();
  const history = useHistory();
  let [createWork, { loading, error: mutationError, data }] = useMutation(
    CREATE_WORK,
    {
      onCompleted({ createWork }) {
        toastWrapper(
          "is-success",
          `Work ${
            createWork.descriptiveMetadata
              ? createWork.descriptiveMetadata.title || ""
              : ""
          } created successfully`
        );
        setShowWorkForm(false);
        history.push(`/work/${createWork.id}`);
      },
      onError(error) {
        setFormError(error);
      },
    }
  );

  if (loading) return <Loading />;

  const onSubmit = (data) => {
    createWork({
      variables: { accessionNumber: data.accessionNumber, title: data.title },
    });
  };

  return (
    <div
      className={`modal ${showWorkForm ? "is-active" : ""}`}
      data-testid="work-form-modal"
    >
      <div className="modal-background"></div>
      <div className="modal-card" style={{ width: "50%" }}>
        <header className="modal-card-head">
          <p className="modal-card-title">Add New Work</p>
          <button
            className="modal-close is-large"
            type="button"
            aria-label="close"
            onClick={() => setShowWorkForm(false)}
          ></button>
        </header>
        <FormProvider {...methods}>
          <form
            onSubmit={methods.handleSubmit(onSubmit)}
            data-testid="work-form"
          >
            <div className="modal-card-body">
              {formError && (
                <div className="notification">
                  <Error error={formError} />
                </div>
              )}
              <UIFormField label="Accession Number">
                <UIFormInput
                  isReactHookForm
                  required
                  label="Accession Number"
                  name="accessionNumber"
                  placeholder="Accession Number"
                  data-testid="accession-number-input"
                />
              </UIFormField>
              <UIFormField label="Work Title">
                <UIFormInput
                  isReactHookForm
                  label="Work Title"
                  data-testid="title-input"
                  name="title"
                  placeholder="Name your work..."
                />
              </UIFormField>
            </div>
            <footer className="modal-card-foot buttons is-right">
              <Button
                isText
                type="button"
                onClick={() => setShowWorkForm(false)}
                data-testid="cancel-button"
                id="cancel-button"
              >
                Cancel
              </Button>
              <Button isPrimary type="submit" data-testid="submit-button">
                Create
              </Button>
            </footer>
          </form>
        </FormProvider>
      </div>
    </div>
  );
};

export default WorkForm;
