import React from "react";
import Collection from "../../components/Collection/Collection";
import { useQuery } from "@apollo/react-hooks";
import { GET_COLLECTION } from "../../components/Collection/collection.query";
import Error from "../../components//UI/Error";
import Loading from "../../components//UI/Loading";
import { Link, useParams } from "react-router-dom";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import Layout from "../Layout";

const ScreensCollection = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const crumbs = [
    {
      label: "Collections",
      route: "/collection/list"
    },
    {
      label: data.collection.name,
      route: `/collection/${id}`,
      isActive: true
    }
  ];

  console.log("data :", data);

  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">{data.collection.name || ""}</h1>
            <h2 className="subtitle">Collection</h2>
            <div className="buttons">
              <Link to={`/collection/form/${id}`} className="button is-primary">
                Edit
              </Link>
              <button className="button">Delete</button>
            </div>
          </div>
        </div>
      </section>
      <UIBreadcrumbs items={crumbs} />
      <section className="section">
        <Collection {...data.collection} />
      </section>
    </Layout>
  );
};

export default ScreensCollection;
