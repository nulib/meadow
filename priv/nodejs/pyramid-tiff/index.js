#!/usr/bin/env node

const pyramid = require("./pyramid");

const handler = async (event, context, _callback) => {
  return await pyramid.createPyramidTiff(event.source, event.target);
}

module.exports = {handler};
