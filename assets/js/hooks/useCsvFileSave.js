import { saveAs } from "file-saver";

export default function useCsvFileSave() {
  return {
    downloadCsvFile: function (fileName = "csv_export", elasticSearchQuery) {
      const formData = new FormData();
      formData.append("query", JSON.stringify({ query: elasticSearchQuery }));

      fetch(`/api/export/${fileName}.csv`, {
        method: "POST",
        body: formData,
      })
        .then((response) => {
          if (!response.ok) {
            throw new Error("Network response not ok");
          }
          return response.blob();
        })
        .then((blob) => {
          saveAs(blob, `${fileName}.csv`);
        })
        .catch((error) => {
          console.error("Error saving CSV export file", error);
        });
    },
  };
}
