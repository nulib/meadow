#!/usr/bin/env node

process.stdin.resume();

process.stdin.on("data", data => {
  var r = Math.floor(Math.random() * 8);
  switch (r) {
    case 1:
      const parsedJSON = JSON.parse(data);
      const target = parsedJSON.target;
      process.stdout.write(`${target} not found`);
      break;
    case 2:
      process.exit(1);
      break;
    case 3:
      break;
    default:
      process.stdout.write("complete");
      break;
  }
});
process.stdin.on("end", () => {
  process.exit;
});

process.stdin.on("exit", () => {
  process.exit;
});
