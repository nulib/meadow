export default async function getVttFile(url) {
  try {
    // Get network request VTT file
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Content-Type": "text/text; charset=utf-8",
      },
    });

    // Handle errors
    if (!response.ok) {
      throw new Error("Error grabbing VTT file");
    }

    // Parse contents and add cues to state
    const vttContents = await response.text();
    const parsed = webvtt.parse(vttContents);
    if (!parsed.valid) {
      throw new Error("Invalid VTT file");
    }
    return parsed;
  } catch (e) {
    console.error("Error loading and parsing VTT file");
    return Promise.resolve();
  }
}
