import { MAX_TRANSCRIPTIONS, arithmetic, runSize } from "./limits";

describe("transcription bench run size", () => {
  it("multiplies images, models and variants", () => {
    const size = runSize(2, 3, 2);
    expect(size.total).toBe(12);
    expect(size.runnable).toBe(true);
    expect(size.overCap).toBe(true);
    expect(arithmetic(size)).toBe(
      "2 images × 3 models × 2 variants = 12 transcriptions",
    );
  });

  it("allows a run of exactly the cap", () => {
    const size = runSize(MAX_TRANSCRIPTIONS, 1, 1);
    expect(size.overCap).toBe(false);
    expect(size.runnable).toBe(true);
    expect(runSize(MAX_TRANSCRIPTIONS + 1, 1, 1).overCap).toBe(true);
  });

  it("is not runnable until something of each kind is picked", () => {
    const size = runSize(1, 0, 4);
    expect(size.runnable).toBe(false);
    expect(size.overCap).toBe(false);
    expect(arithmetic(size)).toBe(
      "1 image × 0 models × 4 variants = 0 transcriptions",
    );
  });
});
