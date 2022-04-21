const fs = require('fs');

const { exit } = require("process");

const sleep = (milliseconds) => {
  const date = Date.now();
  let currentDate = null;
  do {
    currentDate = Date.now();
  } while (currentDate - date < milliseconds);
}

const longData = fs.readFileSync(`${__dirname}/lipsum.txt`).toString()

const testHandler = async (event, _context, _callback) => {

  switch (event.test) {
    case "die": throw "Dying because the caller told me to";
    case "quit": exit(event.status);
    case "long": return { type: "long", result: longData};
    case "null": return null;
    case "undef": return undefined;
    case "sleep": 
      sleep(event.duration);
      return null;
    case "version":
      console.info(`NodeJS ${process.version}`);
      return true;
    default:
      console.debug("ping");
      console.log("This is a log message with level `log`");
      console.debug("ping");
      console.warn("This is a log message with level `warn`");
      console.debug("ping");
      console.error("This is a log message with level `error`");
      console.debug("ping");
      console.debug("This is a log message with level `debug`");
      console.debug("ping");
      console.info("This is a log message with level `info`");
      console.debug("ping");
      console.trace("This is a trace message.")
      console.debug("ping");
      process.stdout.write("This is an unknown message type\n");
      console.debug("ping");
      return { type: "complex", result: event }
  }
}

module.exports = {testHandler}