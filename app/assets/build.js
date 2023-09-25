#!/usr/bin/env node

const aliasGlob = require("./build/esbuild-plugin-alias-glob");
const { copy } = require("esbuild-plugin-copy");
const esbuild = require("esbuild");
const path = require("node:path");
const sassMapper = require("./build/sass-mapper");
const { sassPlugin } = require("esbuild-sass-plugin");
const svgr = require("esbuild-plugin-svgr");

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const cwd = process.cwd();

const elasticsearchIndex = (suffix) =>
  JSON.stringify(
    [process.env.DEV_PREFIX, process.env.DEV_ENV, "dc-v2", suffix]
      .filter((e) => e)
      .join("-"),
  );

const define = {
  __HONEYBADGER_API_KEY__: JSON.stringify(
    process.env.HONEYBADGER_API_KEY_FRONTEND || "",
  ),
  __HONEYBADGER_ENVIRONMENT__: JSON.stringify(
    process.env.HONEYBADGER_ENVIRONMENT || "",
  ),
  __HONEYBADGER_REVISION__: JSON.stringify(
    process.env.HONEYBADGER_REVISION || "",
  ),
  __MEADOW_VERSION__: JSON.stringify(process.env.MEADOW_VERSION || ""),
  __ELASTICSEARCH_WORK_INDEX__: elasticsearchIndex("work"),
  __ELASTICSEARCH_COLLECTION_INDEX__: elasticsearchIndex("collection"),
  __ELASTICSEARCH_FILE_SET_INDEX__: elasticsearchIndex("file-set"),
};

const loader = {
  ".js": "jsx",
  ".png": "file",
};

const plugins = [
  copy({
    assets: {
      from: "./static/**/*",
      to: "..", // relative to `outdir` below
    },
    watch: true,
  }),
  aliasGlob({
    "@js": {
      to: path.resolve(cwd, "./js"),
    },
  }),
  sassPlugin({ cssImports: true, importMapper: sassMapper }),
  svgr(),
];

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
  resolveExtensions: [".mjs", ".js", ".jsx", ".json", ".tsx", ".ts"],
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
