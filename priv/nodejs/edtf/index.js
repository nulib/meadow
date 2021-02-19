#!/usr/bin/env node

const edtf = require("edtf");
edtf.defaults.level = 3;

const functions = {
  validate: async (value) => await edtf(value).edtf,
  parse: async (value) => {
    const replacer = (_key, value) => value === Infinity ? {"type": "Infinity"} : value;
    let result = await edtf.parse(value);
    return JSON.parse(JSON.stringify(result, replacer))
  }
};

const handler = (event, _context, _callback) => {
  return new Promise((resolve, reject) => {
    let func = functions[event.function];
    if (typeof func == "function") {
      func(event.value)
        .catch(_err => reject(`Invalid EDTF input: ${event.value}`))
        .then(data => resolve(data));
    } else {
      reject(`Unknown function: ${event.function}`);
    }
  });
}

module.exports = {handler};