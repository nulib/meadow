#!/usr/bin/env node

import "source-map-support/register.js";
import * as pyramid from "./pyramid.js";

const handler = async (event, _context, _callback) => {
  return await pyramid.createPyramidTiff(event.source, event.target);
}

export { handler };
