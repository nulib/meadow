const index = require("./index");
const payload = require("./event.json");
index.handler(payload, {}).then(console.log);
