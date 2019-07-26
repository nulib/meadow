import { toast } from "react-toastify";
import axios from "axios";

export async function getProject(id) {
  let project = null;

  if (!id) {
    return;
  }

  try {
    const response = await axios.get(`/api/v1/projects/${id}`, {
      responseType: "json"
    });
    if (!response.data) {
      throw new Error(`Error fetching /api/v1/projects/${id}`);
    }
    project = response.data.data;
  } catch (error) {
    console.log("error", error);
    toast(
      `${error.response ? JSON.stringify(error.response.data.errors) : error}`,
      { type: "error" }
    );
  }

  return project;
}
