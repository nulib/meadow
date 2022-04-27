export async function getManifest(url) {
  try {
    //const response = await fetch(`${work.manifestUrl}?${Date.now()}`);
    const response = await fetch(url);
    const data = await response.json();
    return data;
  } catch (error) {
    console.error("Error retrieving manifest url", error);
    return Promise.resolve();
  }
}
