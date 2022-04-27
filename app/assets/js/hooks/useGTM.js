export default function useGTM() {
  /**
   * This function is called between route changes, so the DataLayer always contains
   * accurate data. We provide default values of 'undefined' as a way of flushing
   * stale entries when changing routes.  Only 'isLoggedIn' is sent for all pages.
   * The remaining DataLayer properties are only sent from the Item Details Page.
   */
  function loadDataLayer({
    adminset = undefined,
    collections = undefined,
    creatorsContributors = undefined,
    isPublished = undefined,
    pageTitle = undefined,
    rightsStatement = undefined,
    subjects = undefined,
    visibility = undefined,
  }) {
    const values = {
      adminset,
      collections,
      creatorsContributors,
      event: "react-route-change",
      isLoggedIn: true,
      isPublished,
      pageTitle,
      rightsStatement,
      subjects,
      visibility,
    };

    // Add new values
    window.dataLayer.push(values);
  }

  return {
    loadDataLayer,
  };
}
