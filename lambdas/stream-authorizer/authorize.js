const allowedFromRegexes = ((str) => {
  const configValues = typeof str === "string" ? str.split(";") : [];
  const result = [];
  for (const re in configValues) {
    result.push(new RegExp(configValues[re]));
  }
  return result;
});

async function authorize(id, referer, cookie, config) {
  for (const re of allowedFromRegexes(config.allowedFrom)) {
    if (re.test(referer)) {
      console.log(`Stream authorized: Referred by ${referer}`);
      return true;
    }
  }

  return await getImageAuthorization(id, cookie, config);
}

async function getImageAuthorization(id, cookieHeader, config) {
  const opts = {
    headers: {
      cookie: cookieHeader,
    },
  };

  const response = await fetch(
    `${config.dcApiEndpoint}/file-sets/${id}/authorization`,
    opts
  );
  if (response.status == 204) {
    console.log(`Access to ${id} authorized via API request`);
    return true;
  }

  console.log(`Access to ${id} denied: API response status ${response.status}`);
  return false;
}

export default authorize;