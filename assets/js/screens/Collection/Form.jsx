import React from "react";
import { useParams } from "react-router-dom";
import CollectionForm from "../../components/Collection/Form";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import { GET_COLLECTION } from "../../components/Collection/collection.gql.js";
import { useQuery } from "@apollo/client";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { CodeListProvider } from "@js/context/code-list-context";
import UISkeleton from "@js/components/UI/Skeleton";

const ScreensCollectionForm = () => {
  const { id } = useParams();
  const edit = !!id;
  let collection;
  let crumbs = [
    {
      label: "Collections",
      route: "/collection/list",
    },
  ];

  if (edit) {
    const { data, loading, error } = useQuery(GET_COLLECTION, {
      variables: { id },
    });

    if (loading) return <UISkeleton />;
    if (error) return <Error error={error} />;

    crumbs.push(
      {
        label: data.collection.title,
        route: `/collection/${data.collection.id}`,
      },
      {
        label: "Edit",
        isActive: true,
      }
    );

    collection = data.collection;
  }

  if (!edit) {
    crumbs.push({
      label: "Add",
      isActive: true,
    });
  }

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <UIBreadcrumbs items={crumbs} />
          <div className="box">
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <CollectionForm collection={collection} />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensCollectionForm;
