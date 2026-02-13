const fs = require("node:fs");
const path = require("node:path");
const { defineConfig } = require("vite");
const react = require("@vitejs/plugin-react");
const svgr = require("vite-plugin-svgr").default;

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

function resolveTildeImport(url) {
  const spec = url.slice(1);
  const parts = spec.split("/");
  const packageName = spec.startsWith("@")
    ? parts.slice(0, 2).join("/")
    : parts[0];
  const rest = spec.startsWith("@")
    ? parts.slice(2).join("/")
    : parts.slice(1).join("/");
  const packageRoot = path.resolve(__dirname, "node_modules", packageName);

  if (!fs.existsSync(packageRoot)) return spec;
  if (rest) return path.join(packageRoot, rest);

  const packageJson = path.join(packageRoot, "package.json");
  if (fs.existsSync(packageJson)) {
    const pkg = JSON.parse(fs.readFileSync(packageJson, "utf8"));
    const entry = pkg.sass || pkg.style || pkg.main;
    if (entry) return path.join(packageRoot, entry);
  }

  return packageRoot;
}

module.exports = defineConfig({
  plugins: [react({ jsxRuntime: "classic" }), svgr({ exportAsDefault: true })],
  define,
  publicDir: "static",
  resolve: {
    alias: {
      "@": path.resolve(__dirname),
      "@js": path.resolve(__dirname, "./js"),
    },
    extensions: [".mjs", ".js", ".jsx", ".json", ".tsx", ".ts"],
  },
  esbuild: {
    include: /\/assets\/js\/.*\.[jt]sx?$/,
    loader: "tsx",
  },
  css: {
    preprocessorOptions: {
      scss: {
        includePaths: [path.resolve(__dirname, "node_modules")],
        importer: [
          (url) => {
            if (url.startsWith("~")) {
              return { file: resolveTildeImport(url) };
            }

            return null;
          },
        ],
      },
    },
  },
  build: {
    outDir: "../priv/static",
    emptyOutDir: false,
    target: "es2017",
    sourcemap: true,
    rollupOptions: {
      input: path.resolve(__dirname, "./js/app.jsx"),
      output: {
        entryFileNames: "js/app.js",
        chunkFileNames: "js/[name]-[hash].js",
        assetFileNames: (assetInfo) =>
          assetInfo.name && assetInfo.name.endsWith(".css")
            ? "js/app.css"
            : "js/[name]-[hash][extname]",
      },
    },
  },
});
