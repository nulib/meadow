const exif = require("./exif");

const handler = async (event, _context, _callback) => {
  const result = await exif.extractExif(event.source, event.options)
  if (result === null || result === undefined) {
    return null;
  }
  
  return {
    tool: "exifr",
    tool_version: require("exifr/package.json").version,
    value: result
  };
};

module.exports = { handler };
