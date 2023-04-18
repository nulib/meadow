const fs = require("node:fs");
const { globSync } = require("glob");
const path = require("node:path");

const DEFAULT_EXTENSIONS = [".tsx", ".ts", ".jsx", ".js", ".css", ".json"];

function indexFile(source) {
  const candidate = path.resolve(source, "./index.js");
  if (fs.existsSync(candidate)) return candidate;
  return null;
}

function matchingFile(source, glob) {
  const candidates = globSync(`${source}.{${glob}}`);
  return candidates[0] || source;
}

function resolveFile(source, glob) {
  return indexFile(source) || matchingFile(source, glob);
}

module.exports = (specs) => {
  return {
    name: "aliasGlob",
    setup(build) {
      for (const alias in specs) {
        const { to } = specs[alias];
        const exts = build.initialOptions?.resolveExtensions || DEFAULT_EXTENSIONS;
        const fileGlob = exts.join(",").replaceAll(/\./g, "") || "";
        const filter = new RegExp(`^${alias}/`);
        build.onResolve({ filter }, async (opts) => {
          const source = opts.path.replace(filter, "");
          const result = resolveFile(path.resolve(to, source), fileGlob);
          return { path: result };
        });
      }
    }
  }
};
