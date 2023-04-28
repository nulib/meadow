const esbuild = require("esbuild");
const fs = require("node:fs");
const path = require("node:path");
const { sassPlugin } = require("esbuild-sass-plugin");
const svgr = require("esbuild-plugin-svgr");

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const define = {
  __HONEYBADGER_API_KEY__: JSON.stringify(
    process.env.HONEYBADGER_API_KEY_FRONTEND || ""
  ),
  __HONEYBADGER_ENVIRONMENT__: JSON.stringify(
    process.env.HONEYBADGER_ENVIRONMENT || ""
  ),
  __HONEYBADGER_REVISION__: JSON.stringify(
    process.env.HONEYBADGER_REVISION || ""
  ),
  __MEADOW_VERSION__: JSON.stringify(process.env.MEADOW_VERSION || ""),
  __ELASTICSEARCH_INDEX__: JSON.stringify(
    [process.env.DEV_PREFIX, process.env.DEV_ENV, "meadow"]
      .filter((e) => e)
      .join("-")
  ),
};

const loader = {
  ".js": "jsx",
};

const importMapper = (loc) => {
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

const plugins = [sassPlugin({ cssImports: true, importMapper }), svgr()];

let opts = {
  entryPoints: ["js/app.jsx"],
  bundle: true,
  target: "es2017",
  outdir: "../priv/static/js",
  logLevel: "info",
  sourcemap: "linked",
  define,
  loader,
  plugins,
};

async function watchMode(opts) {
  const ctx = await esbuild.context({ ...opts, sourcemap: "inline" });
  return await ctx.watch();
}

async function deployMode(opts) {
  buildMode({ ...opts, minify: true });
}

async function buildMode(opts) {
  return await esbuild.build(opts);
}

const promise = watch
  ? watchMode(opts)
  : deploy
  ? deployMode(opts)
  : buildMode(opts);

let callback = (_result) => true;
if (watch) {
  callback = (_result) => {
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  };
}

promise.then(callback);
