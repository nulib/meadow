import React from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { IIIF_SERVER_URL } from "./iiif.query";

export const IIIFContext = React.createContext();

export const IIIFProvider = ({ children }) => {
  const { loading, error, data } = useQuery(IIIF_SERVER_URL);

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  return (
    <IIIFContext.Provider value={data ? data.iiifServerUrl.url : null}>
      {children}
    </IIIFContext.Provider>
  );
};
