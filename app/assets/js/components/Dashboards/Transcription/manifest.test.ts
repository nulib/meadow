import { annotationPages, manifestOf, resultKey } from "./manifest";
import type { Result } from "./types";

const result: Result = {
  id: "result-1",
  attempt: 2,
  fileSetId: "file-set-1",
  label: "Page 1",
  imageUrl: "https://iiif.example.edu/iiif/3/file-set-1/",
  model: "us.anthropic.claude-sonnet-4-6",
  variantId: "lines",
  status: "done",
  imageWidth: 4000,
  imageHeight: 2000,
  sentWidth: 2048,
  sentHeight: 1024,
  parsed: {
    text: "Dear Sir,\nno box",
    regions: [
      {
        index: 0,
        level: "lines",
        text: "Dear Sir,",
        box: [0.1, 0.1, 0.2, 0.05],
        rawBox: [205, 102, 614, 154],
        parent: null,
      },
      {
        index: 1,
        level: "words",
        text: "Dear",
        box: [0.1, 0.1, 0.08, 0.05],
        rawBox: [205, 102, 369, 154],
        parent: 0,
      },
      {
        index: 2,
        level: "lines",
        text: "no box",
        box: null,
        rawBox: null,
        parent: null,
      },
    ],
    levels: ["lines", "words"],
    languages: ["en"],
    structured: true,
    warnings: [],
  },
};

describe("transcription bench manifest", () => {
  it("keys a result on its id and attempt", () => {
    expect(resultKey(result)).toBe("result-1-2");
  });

  it("makes one AnnotationPage per level, with boxes in Canvas pixels", () => {
    const pages = annotationPages("run-1", result);
    expect(pages.map((page) => page.label.none[0])).toEqual(["lines", "words"]);

    const [lines, words] = pages;
    expect(lines.items).toHaveLength(2);
    expect(lines.items[0].target).toMatch(/\/canvas#xywh=400,200,800,100$/);
    expect(lines.items[0].motivation).toBe("commenting");
    expect(lines.items[0].body).toEqual({
      type: "TextualBody",
      value: "Dear Sir,",
      format: "text/plain",
      language: "en",
    });
    // A region without a box targets the whole Canvas.
    expect(lines.items[1].target).toMatch(/\/canvas$/);
    expect(words.items[0].target).toMatch(/#xywh=400,200,320,100$/);
  });

  it("puts text without regions on the whole Canvas", () => {
    const pages = annotationPages("run-1", {
      ...result,
      parsed: { ...result.parsed!, regions: [], levels: [], text: "hello" },
    });
    expect(pages).toHaveLength(1);
    expect(pages[0].items[0].body.value).toBe("hello");
    expect(pages[0].items[0].target).toMatch(/\/canvas$/);
  });

  it("builds a one-Canvas Manifest on the file set's IIIF image service", () => {
    const pages = annotationPages("run-1", result);
    const manifest = manifestOf("run-1", result, pages);
    const canvas = manifest.items[0];
    expect(manifest.id).toContain("/run-1/result-1-2/manifest");
    expect(canvas.width).toBe(4000);
    expect(canvas.height).toBe(2000);
    expect(canvas.annotations).toBe(pages);

    const body = canvas.items[0].items[0].body;
    expect(body.service[0]).toEqual({
      id: "https://iiif.example.edu/iiif/3/file-set-1",
      type: "ImageService3",
      profile: "level2",
    });
    expect(body.id).toBe(
      "https://iiif.example.edu/iiif/3/file-set-1/full/max/0/default.jpg",
    );
    expect(lines(pages)[0]).toContain(canvas.id);
  });

  it("falls back to the size of the image sent for the Canvas", () => {
    const sized = { ...result, imageWidth: null, imageHeight: null };
    const manifest = manifestOf("run-1", sized, []);
    expect(manifest.items[0].width).toBe(2048);
    expect(annotationPages("run-1", sized)[0].items[0].target).toMatch(
      /#xywh=205,102,410,51$/,
    );
  });
});

const lines = (pages: ReturnType<typeof annotationPages>) =>
  pages[0].items.map((item) => item.target);
