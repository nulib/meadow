import React from "react";
import PropTypes from "prop-types";
import moment from "moment";
import { useQuery } from "@apollo/client/react";
import { DIGITAL_COLLECTIONS_URL } from "@js/components/UI/ui.gql";
import { useClipboard } from "use-clipboard-copy";
import UISharedLink from "@js/components/UI/SharedLink";

export default function WorkSharedLinkNotification({ linkData }) {
  const { data, loading, error } = useQuery(DIGITAL_COLLECTIONS_URL);
  const clipboard = useClipboard({
    copiedTimeout: 5000,
  });

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
    <UISharedLink
      isWarning
      shareUrl={sharedUrl}
      data-testid="notification-shared-link"
    >
      Your shared link has been created successfully and will expire:{" "}
      <span data-testid="link-date">
        <strong>
          {moment(linkData.expires).format("MMM DD, YYYY h:mm A")}
        </strong>
      </span>
    </UISharedLink>
  );
}

WorkSharedLinkNotification.propTypes = {
  linkData: PropTypes.object,
};
