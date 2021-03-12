import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import { DIGITAL_COLLECTIONS_URL } from "@js/components/UI/ui.gql";
import UISharedLink from "@js/components/UI/SharedLink";

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
    <UISharedLink
      data-testid="notification-public-link"
      isSuccess
      shareUrl={publicUrl}
    >
      This link is publicly available on Digital Collections.
    </UISharedLink>
  );
}

WorkPublicLinkNotification.propTypes = {
  workId: PropTypes.string,
};
