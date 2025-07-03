module.exports = {
  __esModule: true,
  nanoid: () => "mockedNanoid",
  customRandom: jest.fn(() => jest.fn(() => "mockedCustomRandom")),
};
