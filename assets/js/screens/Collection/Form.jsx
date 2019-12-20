import React from "react";
import { useParams } from "react-router-dom";
import CollectionForm from "../../components/Collection/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import { GET_COLLECTION } from "../../components/Collection/collection.query";
import { useQuery } from "@apollo/react-hooks";

const ScreensCollectionForm = () => {
  const { id } = useParams();
  const edit = !!id;
  let collection;
  let crumbs = [
    {
      label: "Collections",
      link: "/collection/list"
    }
  ];

  if (edit) {
    const { data, loading, error } = useQuery(GET_COLLECTION, {
      variables: { id }
    });

    if (loading) return <Loading />;
    if (error) return <Error error={error} />;

    crumbs.push(
      {
        label: data.collection.name,
        link: `/collection/${data.collection.id}`
      },
      {
        label: "Edit",
        link: `/collection/form/${data.collection.id}`
      }
    );

    collection = data.collection;
  }

  if (!edit) {
    crumbs.push({
      label: "Add",
      link: `/collection/form`
    });
  }

  return (
    <>
      <ScreenHeader
        title={`${edit ? "Edit" : "Create"} Collection`}
        description={`${
          edit ? "Edit an existing collection" : "Create a new collection"
        }`}
        breadCrumbs={crumbs}
      />

      <ScreenContent>
        {<CollectionForm collection={collection} />}
      </ScreenContent>
    </>
  );
};

export default ScreensCollectionForm;
