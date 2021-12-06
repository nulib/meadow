import useAcceptedMimeTypes from "./useAcceptedMimeTypes";

describe("useAcceptedMimeTypes hook", () => {
  beforeEach(() => {});
  it("returns invalid with invalid Role or Work Type Id supplied", () => {
    const { isFileValid } = useAcceptedMimeTypes();
    const badRole = isFileValid("B", "AUDIO", "audio/mp3");
    const badWorkType = isFileValid("A", "YO", "audio/mp3");
    expect(badRole.isValid).toBeFalsy();
    expect(badRole.code).toEqual("invalid-fileset-role");
    expect(badWorkType.isValid).toBeFalsy();
    expect(badWorkType.code).toEqual("invalid-work-type");
  });

  it("returns valid state for the supplemental role", () => {
    const { isFileValid } = useAcceptedMimeTypes();
    const result = isFileValid("S", "IMAGE", "application/*");
    expect(result.isValid).toBeTruthy();

    const resultNoMimeType = isFileValid("S", "", "");
    expect(resultNoMimeType.isValid).toBeTruthy();
  });

  it("returns valid states for a auxiliary role", () => {
    const { isFileValid } = useAcceptedMimeTypes();
    const result = isFileValid("X", "IMAGE", "image/jpeg");
    const resultBad = isFileValid("X", "IMAGE", "audio/mp3");
    expect(result.isValid).toBeTruthy();
    expect(resultBad.isValid).toBeFalsy();
    expect(resultBad.code).toEqual("invalid-image");
  });

  describe("Access role", () => {
    const { isFileValid } = useAcceptedMimeTypes();

    it("returns valid states for Image work type", () => {
      const result = isFileValid("A", "IMAGE", "image/tiff");
      const resultBad = isFileValid("A", "IMAGE", "audio/tiff");
      expect(result.isValid).toBeTruthy();
      expect(resultBad.isValid).toBeFalsy();
      expect(resultBad.code).toEqual("invalid-image");
    });

    it("returns valid states for Audio work type", () => {
      const result = isFileValid("A", "AUDIO", "audio/wav");
      const resultBad = isFileValid("A", "AUDIO", "audio/flac");
      const resultBad2 = isFileValid("A", "AUDIO", "video/ogg");
      expect(result.isValid).toBeTruthy();
      expect(resultBad.isValid).toBeFalsy();
      expect(resultBad.code).toEqual("invalid-audio");
      expect(resultBad2.isValid).toBeFalsy();
      expect(resultBad2.code).toEqual("invalid-audio");
    });

    it("returns valid states for Video work type", () => {
      const result = isFileValid("A", "VIDEO", "video/wav");
      const resultBad = isFileValid("A", "VIDEO", "video/x-matroska");
      const resultBad2 = isFileValid("A", "VIDEO", "audio/ogg");
      expect(result.isValid).toBeTruthy();
      expect(resultBad.isValid).toBeFalsy();
      expect(resultBad.code).toEqual("invalid-video");
      expect(resultBad2.isValid).toBeFalsy();
      expect(resultBad2.code).toEqual("invalid-video");
    });
  });

  describe("Preservation role", () => {
    const { isFileValid } = useAcceptedMimeTypes();

    it("returns the correct mime types for Image work type", () => {
      const result = isFileValid("P", "IMAGE", "image/tiff");
      const resultBad = isFileValid("P", "IMAGE", "audio/tiff");
      expect(result.isValid).toBeTruthy();
      expect(resultBad.isValid).toBeFalsy();
      expect(resultBad.code).toEqual("invalid-image");
    });

    it("returns the correct mime types for Audio work type", () => {
      const result = isFileValid("P", "AUDIO", "audio/flac");
      const resultBad = isFileValid("P", "AUDIO", "video/mp4");
      expect(result.isValid).toBeTruthy();
      expect(resultBad.isValid).toBeFalsy();
      expect(resultBad.code).toEqual("invalid-audio");
    });

    it("returns the correct mime types for Video work type", () => {
      const result = isFileValid("P", "VIDEO", "video/mp4");
      const resultBad = isFileValid("P", "VIDEO", "audio/mp4");
      expect(result.isValid).toBeTruthy();
      expect(resultBad.isValid).toBeFalsy();
      expect(resultBad.code).toEqual("invalid-video");
    });
  });
});
