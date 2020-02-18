import React, { useState } from "react";
import PropTypes, { shape } from "prop-types";
import CollectionSearch from "./Search";
import UIButton from "../UI/Button";
import UICard from "../UI/Card";
import UIModalDelete from "../UI/Modal/Delete";
import { DELETE_COLLECTION, GET_COLLECTIONS } from "./collection.query.js";
import { useMutation } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useToasts } from "react-toast-notifications";
import { useHistory } from "react-router-dom";

const Collection = ({
  id,
  adminEmail,
  description,
  featured,
  findingAidUrl,
  keywords = [],
  name,
  published,
  works = []
}) => {
  const [modalOpen, setModalOpen] = useState(false);
  const { addToast } = useToasts();
  const history = useHistory();

  const [deleteCollection, { loading, error, data }] = useMutation(
    DELETE_COLLECTION,
    {
      onCompleted({ deleteCollection }) {
        addToast(`Collection ${deleteCollection.name} deleted successfully`, {
          appearance: "success",
          autoDismiss: true
        });
        history.push("/collection/list");
      },
      refetchQueries(mutationResult) {
        return [{ query: GET_COLLECTIONS }];
      }
    }
  );

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  const handleDeleteClick = () => {
    setModalOpen(false);
    deleteCollection({ variables: { collectionId: id } });
  };

  return (
    <div className="container" data-testid="collection">
      <article className="media">
        <figure className="media-left">
          <p
            className="image is-square"
            style={{ width: "300px", height: "300px" }}
          >
            <img src="https://bulma.io/images/placeholders/480x480.png" />
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
            <dl>
              <dt>
                <strong>Description</strong>
              </dt>
              <dd>{description}</dd>
              <dt>
                <strong>Admin Email</strong>
              </dt>
              <dd>{adminEmail}</dd>
              <dt>
                <strong>Finding Aid URL</strong>
              </dt>
              <dd>{findingAidUrl}</dd>
              <dt>
                <strong>Keywords</strong>
              </dt>
              <dd>{keywords.join(", ")}</dd>
            </dl>
          </div>
        </div>
        <div className="media-right"></div>
      </article>

      <CollectionSearch />
      <UIModalDelete
        isOpen={modalOpen}
        handleClose={() => setModalOpen(false)}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Collection ${name}`}
      />
    </div>
  );
};

Collection.propTypes = {
  collection: shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string,
    description: PropTypes.string,
    keywords: PropTypes.array
  })
};

export default Collection;
