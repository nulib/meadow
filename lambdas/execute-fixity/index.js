const { SFNClient, StartExecutionCommand } = require("@aws-sdk/client-sfn");
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
  var stepfunctions = new SFNClient();
  const cmd = new StartExecutionCommand(params);
  return new Promise((resolve, _reject) => {
    stepfunctions.send(cmd)
    .then((data) => {
      console.log(data);
      resolve({
        statusCode: 200,
        body: JSON.stringify({
          message: "Step function worked",
        }),
      });
    })
    .catch((err) => {
      console.log(err);
      resolve({
        statusCode: 500,
        body: JSON.stringify({
          message: "There was an error",
        }),
      });
    });
  });
};
