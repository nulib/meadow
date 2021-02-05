import { useLocation } from "react-router-dom";

export default function useSearchTerm() {
  const location = useLocation();
  return location.state ? location.state.passedInSearchTerm : null;
}
