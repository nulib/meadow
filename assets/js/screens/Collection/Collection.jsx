import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Collection from "../../components/Collection/Collection";
import { useQuery } from "@apollo/react-hooks";
import { GET_COLLECTION } from "../../components/Collection/collection.query";
import Error from "../../components//UI/Error";
import Loading from "../../components//UI/Loading";
import { useParams } from "react-router-dom";

const ScreensCollection = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const createCrumbs = () => {
    return [
      {
        label: "Collections",
        link: "/collection/list"
      },
      {
        labelWithoutLink: data.collection.name,
        link: `/collection/${id}`
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Collection"
        description="Collection details."
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <Collection {...data.collection} />
      </ScreenContent>
    </>
  );
};

export default ScreensCollection;
