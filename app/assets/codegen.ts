import { CodegenConfig } from "@graphql-codegen/cli";
import path from "path";

const config: CodegenConfig = {
  // TODO: Make the schema URL dynamic.  Where is this URL defined?
  schema: "../priv/graphql/schema.json",
  documents: ["js/**/*.{ts,tsx}", "!js/**/*.mock.*"],
  ignoreNoDocuments: true,
  generates: {
    "./js/__generated__/": {
      preset: "client",
      plugins: [],
      presetConfig: {
        gqlTagName: "gql",
      },
    },
  },
};

export default config;
