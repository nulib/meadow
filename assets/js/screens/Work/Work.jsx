import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORK } from "../../components/Work/work.query";
import { useParams } from "react-router-dom";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import ButtonGroup from "../../components/UI/ButtonGroup";
import useIsEditing from "../../hooks/useIsEditing";
import WorkFormProvider from "../../components/Work/FormProvider";

const ScreensWork = () => {
  const { id } = useParams();
  const [isEditing, setIsEditing] = useIsEditing();
  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const {
    work: { accessionNumber, published }
  } = data;

  const breadCrumbs = [
    {
      label: "Project :: name here",
      route: "/"
    },
    {
      label: "Ingest Sheet :: name here",
      route: "/"
    },
    {
      label: accessionNumber,
      isActive: true
    }
  ];

  const handleSubmit = e => {
    e.preventDefault();

    setIsEditing(false);
    //TODO: Wire this up
  };

  return (
    <Layout>
      <WorkFormProvider isEditing={isEditing}>
        <form name="work-form" data-testid="work-form" onSubmit={handleSubmit}>
          <section className="hero is-light" data-testid="work-hero">
            <div className="hero-body">
              <div className="container">
                <h1 className="title">{accessionNumber}</h1>
                <h2 className="subtitle">Work Accession Number</h2>
                <ButtonGroup>
                  {!published && (
                    <button
                      className="button is-primary"
                      data-testid="publish-button"
                      disabled={isEditing}
                    >
                      {!published ? "Publish" : "Unpublish"}
                    </button>
                  )}
                  {!isEditing && (
                    <button
                      className="button"
                      data-testid="edit-button"
                      onClick={() => setIsEditing(true)}
                    >
                      Edit work
                    </button>
                  )}
                  {isEditing && (
                    <>
                      <button
                        className="button is-primary"
                        data-testid="edit-button"
                        type="submit"
                      >
                        Save work
                      </button>
                      <button
                        className="button"
                        data-testid="edit-button"
                        onClick={() => setIsEditing(false)}
                      >
                        Cancel
                      </button>
                    </>
                  )}
                  <button
                    className="button"
                    data-testid="delete-button"
                    disabled={isEditing}
                  >
                    Delete
                  </button>
                </ButtonGroup>
              </div>
            </div>
          </section>
          <UIBreadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />
          <Work work={data.work} />
        </form>
      </WorkFormProvider>
    </Layout>
  );
};

export default ScreensWork;
