import React from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { IIIF_SERVER_URL } from "./iiif.query";

export const IiifContext = React.createContext();

export const IiifProvider = ({ children }) => {
  const { loading, error, data } = useQuery(IIIF_SERVER_URL);

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  return (
    <IiifContext.Provider value={data ? data.iiifServerUrl.url : null}>
      {children}
    </IiifContext.Provider>
  );
};
