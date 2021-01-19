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
    case "sleep": 
      sleep(event.duration);
      return null;
    default:
      console.log("This is a log message with level `log`");
      console.warn("This is a log message with level `warn`");
      console.error("This is a log message with level `error`");
      console.debug("This is a log message with level `debug`");
      console.info("This is a log message with level `info`");
      console.trace("This is a trace message.")
      process.stdout.write("This is an unknown message type\n");
      return { type: "complex", result: event }
  }
}

module.exports = {testHandler}