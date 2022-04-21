module.exports = (level, message) => {
  const output = [`[${level}]`, message].filter(e => e != null).join(" ") + "\n";
  process.stdout.write(output);
}

