import { useHistory } from "react-router-dom";

export default function useFacetLinkClick() {
  const history = useHistory();
  const handleFacetLinkClick = (facetComponentId, value) => {
    if (!facetComponentId || !value) return;

    history.push("/search", {
      externalFacet: {
        facetComponentId,
        value: value,
      },
    });
  };

  return { handleFacetLinkClick };
}
