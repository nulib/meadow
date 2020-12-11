import { useLocation } from "react-router-dom";
import { extractQueryParts } from "@js/services/elasticsearch";

export default function userPreviousQueryParts() {
  const location = useLocation();
  const prevQuery = location.state ? location.state.prevQuery : "";
  if (!prevQuery) return;
  return extractQueryParts(prevQuery);
}
