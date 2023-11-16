export async function getApiResponse(uri, token) {
  try {
    return await fetch(uri, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
  } catch (error) {
    console.error(error);
  }
}
