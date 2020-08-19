import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";
import moment from "moment";

export default function WorkSharedLinkNotification({ linkData }) {
  const linkUrl = `http://digital-collections.rdc-staging.library.northwestern.edu/shared/${linkData.sharedLinkId}`;

  return (
    <div
      className="notification has-text-centered is-success is-light"
      data-testid="notification-shared-link"
    >
      <p>
        <FontAwesomeIcon icon="link" />
        <span className="px-2">
          Your shared link has been created successfully
        </span>
      </p>
      <p data-testid="link-url">{linkUrl}</p>
      <p data-testid="link-date">
        will expire at: {moment(linkData.expires).format("MMM DD, YYYY h:mm A")}
      </p>
    </div>
  );
}

WorkSharedLinkNotification.propTypes = {
  linkData: PropTypes.object,
};
