import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";
import moment from "moment";
import { useQuery } from "@apollo/client";
import { DIGITAL_COLLECTIONS_URL } from "@js/components/UI/ui.gql";

export default function WorkSharedLinkNotification({ linkData }) {
  const { data, loading, error } = useQuery(DIGITAL_COLLECTIONS_URL);
  const linkUrl = `http://fen.rdc-staging.library.northwestern.edu/shared/${linkData.sharedLinkId}`;

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

  const sharedUrl = `${data.digitalCollectionsUrl.url}shared/${linkData.sharedLinkId}`;

  return (
    <div
      className="notification has-text-centered is-success is-light"
      data-testid="notification-shared-link"
    >
      <p>
        <FontAwesomeIcon icon="link" />
        <span className="px-2">
          Your shared link has been created successfully and will expire:
        </span>
        <span data-testid="link-date">
          <strong>
            {moment(linkData.expires).format("MMM DD, YYYY h:mm A")}
          </strong>
        </span>
      </p>
      <p data-testid="link-url">
        <a href={sharedUrl} target="_blank">
          {sharedUrl}
        </a>
      </p>
    </div>
  );
}

WorkSharedLinkNotification.propTypes = {
  linkData: PropTypes.object,
};
