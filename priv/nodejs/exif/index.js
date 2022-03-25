const exif = require("./exif");

const handler = async (event, _context, _callback) => {
  const result = await exif.extract(event.source);
  if (result === null || result === undefined) {
    return null;
  }
  delete result.SourceFile;
  
  return {
    tool: "exiftool",
    tool_version: await exif.version(),
    value: result
  };
};

module.exports = { handler };
