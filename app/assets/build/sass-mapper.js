const fs = require("node:fs");
const path = require("node:path");

module.exports = (loc) => {
  const relativePathResolver = new RegExp(
    "^(?<prefix>.+?/)(node_modules/.+/)(?<path>node_modules/.+$)"
  );
  let result = loc.replace(relativePathResolver, "$<prefix>$<path>");

  if (result.startsWith("@")) {
    result = path.join(process.cwd(), "node_modules", result);
  }

  if (fs.existsSync(path.join(result, "package.json"))) {
    const spec = JSON.parse(fs.readFileSync(path.join(result, "package.json")));
    result = path.join(result, spec.sass || spec.main);
  }

  return result;
};