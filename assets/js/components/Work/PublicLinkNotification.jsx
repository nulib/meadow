import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import { DIGITAL_COLLECTIONS_URL } from "@js/components/UI/ui.gql";

export default function WorkPublicLinkNotification({ workId }) {
  const { data, loading, error } = useQuery(DIGITAL_COLLECTIONS_URL);

  if (error) {
    return (
      <p className="notifcation is-danger">
        There was an error retrieving the Digital Collections url
      </p>
    );
  }

  if (loading) {
    return null;
  }

  const publicUrl = `${data.digitalCollectionsUrl.url}items/${workId}`;

  return (
    <div
      className="notification has-text-centered is-success is-light"
      data-testid="notification-public-link"
    >
      <p>
        <FontAwesomeIcon icon="link" />
        <span className="px-2">
          Good News! This link is publicly available on Digital Collections.
          Here's the Link
        </span>
      </p>
      <p data-testid="link-url">
        <a href={publicUrl} target="_blank">
          {publicUrl}
        </a>
      </p>
    </div>
  );
}

WorkPublicLinkNotification.propTypes = {
  workId: PropTypes.string,
};
