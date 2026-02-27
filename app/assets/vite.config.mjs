import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import svgr from "vite-plugin-svgr";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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

export default defineConfig({
  plugins: [react({ jsxRuntime: "classic" }), svgr({ exportAsDefault: true })],
  define,
  publicDir: "static",
  resolve: {
    alias: [
      {
        find: "@",
        replacement: path.resolve(__dirname),
      },
      {
        find: "@js",
        replacement: path.resolve(__dirname, "./js"),
      },
    ],
    extensions: [".mjs", ".js", ".jsx", ".json", ".tsx", ".ts"],
  },
  esbuild: {
    include: /\/assets\/js\/.*\.[jt]sx?$/,
    loader: "tsx",
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: "modern-compiler",
        includePaths: [path.resolve(__dirname, "node_modules")],
        quietDeps: true,
        silenceDeprecations: ["import"],
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
