const path = require("path");
const glob = require("glob");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const Webpack = require("webpack");

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new TerserPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({}),
    ],
    splitChunks: {
      chunks: "all",
    },
  },
  entry: {
    app: "./js/app.jsx",
  },
  output: {
    //filename: "app.js",
    // `filename` provides a template for naming your bundles (remember to use `[name]`)
    filename: "[name].bundle.js",
    // `chunkFilename` provides a template for naming code-split bundles (optional)
    chunkFilename: "[name].bundle.js",
    path: path.resolve(__dirname, "../priv/static/js"),
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
        },
      },
      {
        test: /\.mjs$/,
        include: /node_modules/,
        type: "javascript/auto",
      },
      {
        test: /\.(sa|sc|c)ss$/,
        use: [
          MiniCssExtractPlugin.loader,
          { loader: "css-loader", options: {} },
          { loader: "sass-loader", options: {} },
        ],
      },
      {
        test: /\.(woff(2)?|ttf|eot|otf)(\?v=\d+\.\d+\.\d+)?$/,
        use: [
          {
            loader: "url-loader?limit=100000",
          },
        ],
      },
      {
        test: /\.svg$/,
        // Info: https://blog.logrocket.com/how-to-use-svgs-in-react/
        use: ["@svgr/webpack"],
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: "../css/app.css" }),
    new CopyWebpackPlugin({
      patterns: [{ from: "static/", to: "../" }],
    }),
    new Webpack.DefinePlugin({
      __HONEYBADGER_API_KEY__: JSON.stringify(process.env.HONEYBADGER_API_KEY),
      __HONEYBADGER_ENVIRONMENT__: JSON.stringify(
        process.env.HONEYBADGER_ENVIRONMENT
      ),
      __HONEYBADGER_REVISION__: JSON.stringify(
        process.env.HONEYBADGER_REVISION
      ),
      __MEADOW_VERSION__: JSON.stringify(process.env.MEADOW_VERSION),
    }),
  ],
  devtool: "source-map",
  resolve: {
    extensions: ["*", ".mjs", ".js", ".jsx", ".json"],
    // When testing npm components locally, tell Meadow to only
    // use it's React, not the npm module's React
    alias: {
      react: path.resolve(__dirname, "./node_modules/react"),
      "@js": path.resolve(__dirname, "./js"),
    },
  },
});
