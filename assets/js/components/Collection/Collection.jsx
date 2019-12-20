import React, { useState } from "react";
import PropTypes, { shape } from "prop-types";
import EditIcon from "../../../css/fonts/zondicons/edit-pencil.svg";
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

const Collection = ({ id, name, description, keywords = [] }) => {
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
    <div data-testid="collection">
      <UICard>
        <header className="flex flex-row justify-between mb-4">
          <h1>{name}</h1>
          <div>
            <UIButton onClick={() => history.push(`/collection/form/${id}`)}>
              <EditIcon className="icon" /> Edit
            </UIButton>
            <button
              className="btn-link ml-4"
              onClick={() => setModalOpen(true)}
            >
              Delete
            </button>
          </div>
        </header>
        <section className="flex flex-col sm:flex-row">
          <div className="sm:w-1/2">
            <img
              src="/images/placeholder-content.png"
              alt="Placeholder for collection"
            />
          </div>
          <div className="pl-4 sm:w-1/2">
            <div className="h-32 border border-gray-300 overflow-y-scroll mb-4 p-2">
              {description}
            </div>
            <p>Admin@admin.com</p>
            <p>Finding aid</p>
            <dl>
              <dt>Keywords</dt>
              <dd>{keywords.join(", ")}</dd>
            </dl>
          </div>
        </section>
      </UICard>

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
