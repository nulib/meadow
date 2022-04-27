import { useHistory } from "react-router-dom";

export default function usePassedInSearchTerm() {
  const history = useHistory();
  const handlePassedInSearchTerm = (field, value) => {
    if (!field || !value) return;

    history.push("/search", {
      passedInSearchTerm: `${field}:\"${value}\"`,
    });
  };

  return { handlePassedInSearchTerm };
}
