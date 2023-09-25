var aws = require("aws-shim");
const stateMachineArn = process.env.stateMachineArn;

const fullyDecode = (str) => decodeURIComponent(str.replace(/\+/g, " "));

exports.handler = (event, context, callback) => {
  var params = {
    stateMachineArn: stateMachineArn,
    input: JSON.stringify({
      Bucket: fullyDecode(event.Records[0].s3.bucket.name),
      Key: fullyDecode(event.Records[0].s3.object.key),
    }),
  };
  var stepfunctions = new aws.StepFunctions();
  stepfunctions.startExecution(params, (err, data) => {
    if (err) {
      console.log(err);
      const response = {
        statusCode: 500,
        body: JSON.stringify({
          message: "There was an error",
        }),
      };
      callback(null, response);
    } else {
      console.log(data);
      const response = {
        statusCode: 200,
        body: JSON.stringify({
          message: "Step function worked",
        }),
      };
      callback(null, response);
    }
  });
};
