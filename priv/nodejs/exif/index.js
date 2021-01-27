const exif = require("./exif");

const handler = async (event, _context, _callback) => {
  return await exif.extractExif(event.source, event.options);
};

module.exports = { handler };
