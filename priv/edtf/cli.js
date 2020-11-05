#!/usr/bin/env node

const edtf = require("edtf");
const portlog = require("./portlog");
edtf.defaults.level = 3;

function validate(value) {
  try {
    portlog("true", edtf(value).edtf);
  } catch (_err) {
    portlog("false", `Invalid EDTF input: ${value}`);
  }
}

function parse(value) {
  const replacer = (_key, value) => value === Infinity ? {"type": "Infinity"} : value
  
  try {
    portlog("ok", JSON.stringify(edtf.parse(value), replacer));
  } catch (_err) {
    portlog("error", `Invalid EDTF input: ${value}`);
  }
}

process.stdin.resume();

process.stdin.on("data", (data) => {
  const {cmd, value} = JSON.parse(data);
  switch(cmd) {
    case "parse":
      parse(value);
      break;
    case "validate":
      validate(value);
      break;
    default:
      portlog("error", `Unknown command: ${cmd}`);
      break;
  }
});

process.stdin.on("end", () => {
  process.exit;
});

process.stdin.on("exit", () => {
  process.exit;
});
