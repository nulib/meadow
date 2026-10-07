#!/usr/bin/env bun

import { addContentCredentials } from "../c2pa.js";
import { parser } from "@node-cli/parser";

import fs from "fs";
import path from "path";

const { flags, parameters, showHelp } = parser({
  meta: import.meta,
  flags: {
    mimeType: {
      shortFlag: "m",
      description: "MIME type of the source file",
      type: "string",
      default: "image/tiff"
    },
    title: {
      shortFlag: "t",
      description: "Title of the content",
      type: "string"
    },
    output: {
      shortFlag: "o",
      description: "Output type (embedded|sidecar)",
      type: "string",
      default: "embedded"
    },
    help: {
      shortFlag: "h",
      description: "Display help instructions",
      type: "boolean"
    },
    version: {
      shortFlag: "v",
      description: "Output the current version",
      type: "boolean"
    }
  },
  parameters: {
    input_file: {
      description: "Source file to be attested"
    },
    output_file: {
      description: "Destination file for the attested output"
    }
  },
  restrictions: [
    {
      exit: 1,
      message: "Output must be either 'embedded' or 'sidecar'",
      test: (x) => !["embedded", "sidecar"].includes(x.output)
    }
  ],
  usage: true
});

const source = parameters["0"];
const dest = parameters["1"];

if (!source || !dest) {
  showHelp();
  process.exit(1);
}

const sidecar = flags.output === "sidecar";
const mimeType = flags.mimeType;
const title = flags.title || path.basename(source);

console.log(`Adding content credentials to ${source} (${sidecar ? "sidecar" : "embedded"})`);

const buffer = fs.readFileSync(source);
const actions = [
  {
    action: "c2pa.created",
    digitalSourceType: "http://cv.iptc.org/newscodes/digitalsourcetype/digitalCapture",
    softwareAgent:
      "Adobe Photoshop 2024 (https://www.adobe.com/products/photoshop.html)",
    parameters: {
      outputFormat: "image/tiff",
      description: ["Digitized from original source"].join("; ")
    }
  }
];

const result = await addContentCredentials(
  buffer,
  { create: "http://cv.iptc.org/newscodes/digitalsourcetype/digitalCapture" },
  actions,
  { manifestOnly: sidecar, mimeType: mimeType, title }
);

console.log(`Writing attested content to ${dest}`);

fs.writeFileSync(dest, result);
