import { extractQueryParts } from "@js/services/reactive-search";
import { useLocation } from "react-router-dom";

export default function userPreviousQueryParts() {
  const location = useLocation();
  const prevQuery = location.state ? location.state.prevQuery : "";

  if (!prevQuery) return;
  return extractQueryParts(prevQuery);
}
