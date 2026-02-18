import "@testing-library/jest-dom";

jest.setTimeout(10000);
jest.mock("@js/services/elasticsearch");
jest.mock("@nulib/use-markdown");

if (typeof globalThis.fetch !== "function") {
  Object.defineProperty(globalThis, "fetch", {
    configurable: true,
    writable: true,
    value: jest.fn(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: async () => ({}),
        text: async () => "",
      }),
    ),
  });
}
