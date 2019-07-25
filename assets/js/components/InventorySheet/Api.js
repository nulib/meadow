import { toast } from "react-toastify";
import axios from "axios";

export async function getInventorySheet(projectId, inventorySheetId) {
  let inventorySheet = null;

  if (!projectId || !inventorySheetId) {
    return;
  }

  try {
    const response = await axios.get(
      `/api/v1/projects/${projectId}/ingest_jobs/${inventorySheetId}`,
      {
        responseType: "json"
      }
    );
    if (!response.data) {
      throw new Error(`Error fetching Inventory sheet`);
    }
    inventorySheet = response.data.data;
  } catch (error) {
    console.log("error", error);
    toast(
      `${error.response ? JSON.stringify(error.response.data.errors) : error}`,
      { type: "error" }
    );
  }

  return inventorySheet;
}
