export async function getApiResponseHeaders(uri, token) {
  return new Promise((resolve, reject) => {
    process.nextTick(() =>
      resolve({
        "content-length": "3748",
        "content-type": "application/json; charset=UTF-8",
        date: "Tue, 29 Aug 2033 19:37:08 GMT",
        etag: "aeff5e8cec79a6c5041211d1bab7a137",
      })
    );
  });
}
