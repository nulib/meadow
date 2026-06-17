// Asset bundler built on esbuild, replacing the previous Vite build.
//
//   node build.mjs                  one-off development build
//   node build.mjs --production      minified production build (used by `deploy`)
//   node build.mjs --watch          rebuild on change (used by `watch`)
//
// esbuild is what Phoenix ships by default and what Vite wraps internally; it
// handles the CJS/ESM interop in our dependency graph correctly (bun's own
// bundler does not). It must run under node, not bun: esbuild's plugin IPC
// deadlocks on watch rebuilds under bun. bun is still used for installs and
// tests. esbuild has no native SCSS or SVGR support, so the two plugins below
// add them.

import * as esbuild from "esbuild";
import { transform as svgrTransform } from "@svgr/core";
import * as sass from "sass";
import path from "node:path";
import { fileURLToPath } from "node:url";
import fs from "node:fs/promises";
import { readFileSync } from "node:fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const flags = new Set(process.argv.slice(2));
const watch = flags.has("--watch");
const production =
  flags.has("--production") || process.env.NODE_ENV === "production";

// --- compile-time defines (mirrors the old vite.config.mjs) ---------------

const meadowPrefix =
  process.env.MEADOW_TENANT === "meadow"
    ? []
    : [process.env.MEADOW_TENANT] || [
        process.env.DEV_PREFIX,
        process.env.DEV_ENV,
      ];

const elasticsearchIndex = (suffix) =>
  JSON.stringify([...meadowPrefix, "dc-v2", suffix].filter((e) => e).join("-"));

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

// --- plugins --------------------------------------------------------------

// Resolve bare `@import "pkg"` specifiers to a package's `sass`/`style`/`main`
// entry — sass only calls this when its own load-path resolution fails.
const sassPackageImporter = {
  findFileUrl(url) {
    if (url.startsWith(".") || url.startsWith("/")) return null;
    const segments = url.split("/");
    const [pkg, ...rest] = url.startsWith("@")
      ? [segments.slice(0, 2).join("/"), ...segments.slice(2)]
      : [segments[0], ...segments.slice(1)];
    const pkgDir = path.resolve(__dirname, "node_modules", pkg);
    if (rest.length > 0)
      return new URL(`file://${path.join(pkgDir, rest.join("/"))}`);

    const meta = JSON.parse(
      readFileSync(path.join(pkgDir, "package.json"), "utf8"),
    );
    const entry = meta.sass || meta.style || meta.main;
    if (!entry) return null;
    return new URL(`file://${path.join(pkgDir, entry)}`);
  },
};

const scssPlugin = {
  name: "scss",
  setup(build) {
    build.onLoad({ filter: /\.scss$/ }, (args) => {
      const { css, loadedUrls } = sass.compile(args.path, {
        loadPaths: [path.resolve(__dirname, "node_modules")],
        importers: [sassPackageImporter],
        quietDeps: true,
        silenceDeprecations: ["import"],
        style: production ? "compressed" : "expanded",
      });
      // sass reads the @import'ed partials itself, so esbuild can't see them.
      // Report them as watchFiles so editing e.g. scss/_base.scss rebuilds.
      const watchFiles = loadedUrls
        .filter((url) => url.protocol === "file:")
        .map((url) => fileURLToPath(url));
      // esbuild then inlines @imports (e.g. leaflet's CSS) and url() assets.
      return {
        contents: css,
        loader: "css",
        resolveDir: __dirname,
        watchFiles,
      };
    });
  },
};

const resolveAlias = (specifier, resolveDir) => {
  if (specifier.startsWith("@js/"))
    return path.resolve(__dirname, "js", specifier.slice("@js/".length));
  if (specifier.startsWith("@/"))
    return path.resolve(__dirname, specifier.slice("@/".length));
  return path.resolve(resolveDir, specifier);
};

const svgrPlugin = {
  name: "svgr",
  setup(build) {
    // `import Logo from "...northwesternN.svg?react"` -> a React component
    build.onResolve({ filter: /\.svg\?react$/ }, (args) => ({
      path: resolveAlias(args.path.replace(/\?react$/, ""), args.resolveDir),
      namespace: "svgr",
    }));

    build.onLoad({ filter: /\.svg$/, namespace: "svgr" }, async (args) => {
      const svg = await fs.readFile(args.path, "utf8");
      const contents = await svgrTransform(
        svg,
        { plugins: ["@svgr/plugin-jsx"], exportType: "default" },
        { filePath: args.path, componentName: "SvgComponent" },
      );
      return { contents, loader: "jsx", resolveDir: path.dirname(args.path) };
    });
  },
};

// --- build ----------------------------------------------------------------

const outdir = path.resolve(__dirname, "../priv/static");

async function copyStaticDir() {
  // Vite's `publicDir` copied static/ into the output; reproduce that here.
  await fs.cp(path.resolve(__dirname, "static"), outdir, { recursive: true });
}

const buildOptions = {
  entryPoints: [path.resolve(__dirname, "js/app.jsx")],
  bundle: true,
  outdir,
  format: "esm",
  platform: "browser",
  target: ["es2017"],
  splitting: true,
  sourcemap: true,
  minify: production,
  define,
  jsx: "transform",
  loader: {
    ".js": "jsx",
    ".png": "dataurl",
    ".gif": "dataurl",
    ".svg": "dataurl",
    ".woff": "file",
    ".woff2": "file",
    ".ttf": "file",
  },
  // Mirror the old Vite output layout: js/app.js, js/app.css, js/<chunk>-<hash>.js
  entryNames: "js/[name]",
  chunkNames: "js/[name]-[hash]",
  assetNames: "js/[name]-[hash]",
  logLevel: "info",
  plugins: [scssPlugin, svgrPlugin],
};

await copyStaticDir();

if (watch) {
  const ctx = await esbuild.context(buildOptions);
  await ctx.watch();
  console.log("watching for changes…");
} else {
  await esbuild.build(buildOptions);
}
