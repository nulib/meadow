import React from "react";
import { useParams } from "react-router-dom";
import CollectionForm from "../../components/Collection/Form";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import UILoadingPage from "../../components/UI/LoadingPage";
import { GET_COLLECTION } from "../../components/Collection/collection.query";
import { useQuery } from "@apollo/react-hooks";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensCollectionForm = () => {
  const { id } = useParams();
  const edit = !!id;
  let collection;
  let crumbs = [
    {
      label: "Collections",
      route: "/collection/list"
    }
  ];

  if (edit) {
    const { data, loading, error } = useQuery(GET_COLLECTION, {
      variables: { id }
    });

    if (loading) return <UILoadingPage />;
    if (error) return <Error error={error} />;

    crumbs.push(
      {
        label: data.collection.name,
        route: `/collection/${data.collection.id}`
      },
      {
        label: "Edit",
        isActive: true
      }
    );

    collection = data.collection;
  }

  if (!edit) {
    crumbs.push({
      label: "Add",
      isActive: true
    });
  }

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <div className="columns is-centered">
            <div className="column is-two-thirds-desktop">
              <UIBreadcrumbs items={crumbs} />
              <div className="box">
                <h1 className="title" data-testid="collection-form-title">
                  {collection ? "Edit" : "Add New"} Collection
                </h1>
                <CollectionForm collection={collection} />
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensCollectionForm;
