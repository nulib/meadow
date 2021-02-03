const exif = require("./exif");

const handler = async (event, context, _callback) => {
  context.callbackWaitsForEmptyEventLoop = false;
  return await exif.extractExif(event.source, event.options);
};

module.exports = { handler };
