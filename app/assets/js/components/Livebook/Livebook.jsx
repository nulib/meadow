import React from "react";
import { useQuery } from "@apollo/client/react";
import { LIVEBOOK_URL } from "@js/components/UI/ui.gql";

export default function LivebookLink({children}) {
  const { data, loading, error } = useQuery(LIVEBOOK_URL);

  if (error) {
    return (
      <p className="notifcation is-danger">
        There was an error retrieving the Livebook url
      </p>
    );
  }

  if (loading) {
    return null;
  }

  return (
    data?.livebookUrl?.url ? <a href={data.livebookUrl.url} target="_blank">{children}</a> : <></>
  )
}