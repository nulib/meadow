const AWS = require('aws-sdk');
const MediaInfo = require('mediainfo.js');
const URI = require('uri-js');

const makeCallbacks = (input) => {
  const s3 = new AWS.S3();

  const getSize = () => {
    return new Promise((resolve, reject) => {
      s3.headObject(input, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data.ContentLength);
        };
      })
    });  
  };

  const readChunk = (length, offset) => {
    return new Promise((resolve, _reject) => {
      if (length < 1) {
        resolve("");
      } else {
        let params = {...input};
    
        if (typeof offset === 'number') {
          let end = length ? offset + length - 1 : undefined;
          params.Range = `bytes=${[offset, end].join('-')}`;
        }
    
        s3.getObject(params, (err, data) => {
          if (err) {
            console.error(err);
            resolve(undefined);
          } else {
            resolve(data.Body);
          }
        });
      }
    });
  };

  return { getSize, readChunk };
};

const handler = async (event, _context, _callback) => {
  const analyzer = await MediaInfo();
  const uri = URI.parse(event.source);
  const s3Location = { 
    Bucket: uri.host, 
    Key: uri.path.replace(/^\/+/, "")
  };
  const { getSize, readChunk } = makeCallbacks(s3Location);
  
  try {
    const objectSize = await getSize();
    const result = await analyzer.analyzeData(() => objectSize, readChunk);

    if (result === null || result === undefined) {
      return null;
    }
  
    return {
      tool: "mediainfo",
      tool_version: require('mediainfo.js/package.json').version,
      value: result
    };
  } catch(err) {
    const message = err.code ? `${err.statusCode} ${err.code}` : err.toString();
    throw new Error(`Cannot access ${event.source}: ${message}`);
  };
};

module.exports = { handler };