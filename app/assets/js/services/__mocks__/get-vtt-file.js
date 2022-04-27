const mockVttFileParsed = {
  valid: true,
  cues: [
    {
      identifier: "ABC001",
      start: 0,
      end: 1,
      text: "Hello world!",
      styles: "",
    },
    {
      identifier: "ABC002",
      start: 30,
      end: 31,
      text: "This is a subtitle",
      styles: "align:start line:0%",
    },
    {
      identifier: "ABC003",
      start: 60,
      end: 61,
      text: "Foo",
      styles: "",
    },
    {
      identifier: "ABC004",
      start: 110,
      end: 111,
      text: "Bar",
      styles: "",
    },
  ],
};

export default async function getVttFile(url) {
  return new Promise((resolve, reject) => {
    process.nextTick(() => resolve(mockVttFileParsed));
  });
}
