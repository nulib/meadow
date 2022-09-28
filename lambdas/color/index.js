const AWS = require("aws-sdk");
const URI = require("uri-js");
const { getColorFromURL } = require("color-thief-node");
var convert = require("color-convert");

const s3 = new AWS.S3();

AWS.config.update({ httpOptions: { timeout: 600000 } });

const handler = async (event, _context, _callback) => {
  [r, g, b] = await getColorFromURL(
    `${event.source}/square/500,/0/default.jpg`
  );
  console.log(`Extracted RGB: ${r},${g},${b}`);
  [h, s, l] = convert.rgb.hsl(r, g, b);
  console.log(`converted hsl: ${h},${s},${l}}`);
  return { h: h, s: s, l: l };
};

module.exports = { handler };
