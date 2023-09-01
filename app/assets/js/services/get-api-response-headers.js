export async function getApiResponseHeaders(uri, token) {
  try {
    return await fetch(uri, {
      method: "HEAD",
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }).then((response) => response.headers);
  } catch (error) {
    console.error(
      "There was an error fetching the etag from the API response headers.",
      error
    );
  }
}
