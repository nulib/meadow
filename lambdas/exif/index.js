const exif = require("./exif");
const fs = require('fs');

const cleanTmpFiles = () => {
  fs.readdirSync('/tmp')
    .filter(fn => fn.startsWith('exif-'))
    .map(fn => {
      const path = `/tmp/${fn}`;
      console.log(`Cleaning up ${path}`);
      fs.unlinkSync(path);
    });
}

const handler = async (event, _context, _callback) => {
  cleanTmpFiles();
  const source = event.source || event.headers['x-source-location'];
  const result = await exif.extract(source);
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
