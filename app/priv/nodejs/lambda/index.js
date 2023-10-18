#!/usr/bin/env node

// Take over the global `console` object to handle communication with
// the parent process
const writeln = (message) => process.stdout.write(message.trim() + "\n");
const portlog = (level, ...args) =>
  writeln([`[${level}]`, ...args].filter((e) => e != null).join(" "));

["log", "debug", "info", "warn", "error"].forEach((level) => {
  let outLevel = level == "log" ? "info" : level;
  global.console[level] = (...args) => portlog(outLevel, ...args);
});

// Load the lambda script
const script = process.argv[2].replace(/\.js$/, "");
const lambda = process.argv[3];

const handler = require(script)[lambda];

// Listen for invocations from the parent process
process.stdin.resume();
process.stdin.on("data", (data) => {
  const payload = JSON.parse(data);
  handler(payload, {})
    .then((result) => writeln("[return] " + JSON.stringify(result)))
    .catch((err) => writeln("[fatal] " + err));
});

process.stdin.on("end", () => {
  process.exit;
});

process.stdin.on("exit", () => {
  process.exit;
});
