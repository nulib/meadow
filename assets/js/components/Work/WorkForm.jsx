import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/client";
import { CREATE_WORK, GET_WORK_TYPES } from "./work.gql.js";
import { useForm, FormProvider } from "react-hook-form";
import Error from "@js/components/UI/Error";
import Loading from "@js/components/UI/Loading";
import { toastWrapper } from "@js/services/helpers";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import { Button, Notification } from "@nulib/admin-react-components";
import { useHistory } from "react-router-dom";

const WorkForm = ({ showWorkForm, setShowWorkForm }) => {
  const [formError, setFormError] = useState();
  const methods = useForm();
  const history = useHistory();
  let {
    data: workTypeData,
    loading: workTypeLoading,
    error: workTypeError,
  } = useQuery(GET_WORK_TYPES);
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

  if (mutationError || workTypeError)
    return (
      <Notification isDanger>
        Error loading GraphQL data: {mutationError || workTypeError}
      </Notification>
    );
  if (loading) return <Loading />;

  const onSubmit = (data) => {
    createWork({
      variables: {
        accessionNumber: data.accessionNumber,
        title: data.title,
        workType: { id: data.workType, scheme: "WORK_TYPE" },
      },
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
          <p className="modal-card-title">Add new Work</p>
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
                <Notification>
                  <Error error={formError} />
                </Notification>
              )}
              <UIFormField label="Work accession number">
                <UIFormInput
                  isReactHookForm
                  required
                  label="Work accession number"
                  name="accessionNumber"
                  placeholder="Work accession number"
                  data-testid="accession-number-input"
                />
              </UIFormField>
              <UIFormField label="Work title">
                <UIFormInput
                  isReactHookForm
                  label="Work title"
                  data-testid="title-input"
                  name="title"
                  placeholder="Name your work..."
                />
              </UIFormField>
              <UIFormField label="Work type">
                <UIFormSelect
                  isReactHookForm
                  name="workType"
                  options={workTypeData?.codeList}
                  data-testid="work-type"
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
