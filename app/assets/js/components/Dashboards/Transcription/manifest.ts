// A result as IIIF: a one-Canvas Manifest of the file set's image for Clover, and the
// regions as AnnotationPages, one per level ("lines", "words").

import type { Region, Result } from "./types";

// Clover reads `supplementing` text on a region as OCR: kept out of the Annotations list
// and off the Canvas until a Content Search finds in it. The bench wants every box drawn
// and listed, so its annotations are `commenting`. dc-api-v2 would publish the same
// regions as `supplementing`.
const MOTIVATION = "commenting";

export interface Annotation {
  id: string;
  type: "Annotation";
  motivation: string;
  body: {
    type: "TextualBody";
    value: string;
    format: "text/plain";
    language?: string;
  };
  target: string;
}

export interface AnnotationPage {
  id: string;
  type: "AnnotationPage";
  label: { none: string[] };
  items: Annotation[];
}

/** Changes when a result is run again, so the viewer takes it as a new Manifest. */
export const resultKey = (result: Pick<Result, "id" | "attempt">) =>
  `${result.id}-${result.attempt ?? 0}`;

const baseOf = (runId: string, result: Result) =>
  `${window.location.origin}/transcription-bench/${runId}/${resultKey(result)}`;

/** The Canvas is the full image; without its size, the size of the image sent. */
function canvasSize(result: Result) {
  const width = result.imageWidth || result.sentWidth || 1000;
  const height = result.imageHeight || result.sentHeight || 1000;
  return { width, height };
}

function targetOf(
  canvas: string,
  region: Region,
  width: number,
  height: number,
) {
  if (!region.box) return canvas;
  const [x, y, w, h] = region.box;
  const xywh = [x * width, y * height, w * width, h * height].map(Math.round);
  return `${canvas}#xywh=${xywh.join(",")}`;
}

export function annotationPages(
  runId: string,
  result: Result,
): AnnotationPage[] {
  const parsed = result.parsed;
  if (!parsed) return [];
  const { width, height } = canvasSize(result);
  const base = baseOf(runId, result);
  const canvas = `${base}/canvas`;
  const languages = parsed.languages ?? [];
  const language = languages.length === 1 ? languages[0] : undefined;
  const annotation = (
    id: string,
    value: string,
    target: string,
  ): Annotation => ({
    id,
    type: "Annotation",
    motivation: MOTIVATION,
    body: {
      type: "TextualBody",
      value,
      format: "text/plain",
      ...(language && { language }),
    },
    target,
  });

  const regions = parsed.regions ?? [];
  if (!regions.length) {
    if (!parsed.text) return [];
    const id = `${base}/annotations/text`;
    return [
      {
        id,
        type: "AnnotationPage",
        label: { none: ["text (no regions)"] },
        items: [annotation(`${id}/0`, parsed.text, canvas)],
      },
    ];
  }

  return (parsed.levels ?? []).map((level) => {
    const id = `${base}/annotations/${level}`;
    return {
      id,
      type: "AnnotationPage",
      label: { none: [level] },
      items: regions
        .filter((region) => region.level === level)
        .map((region) =>
          annotation(
            `${id}/${region.index}`,
            region.text,
            targetOf(canvas, region, width, height),
          ),
        ),
    };
  });
}

export function manifestOf(
  runId: string,
  result: Result,
  pages: AnnotationPage[],
) {
  const base = baseOf(runId, result);
  const canvas = `${base}/canvas`;
  const { width, height } = canvasSize(result);
  const service = (result.imageUrl ?? "").replace(/\/+$/, "");
  const label = result.label || result.fileSetId;
  return {
    "@context": "http://iiif.io/api/presentation/3/context.json",
    id: `${base}/manifest`,
    type: "Manifest",
    label: { none: [label] },
    items: [
      {
        id: canvas,
        type: "Canvas",
        label: { none: [label] },
        width,
        height,
        items: [
          {
            id: `${canvas}/painting`,
            type: "AnnotationPage",
            items: [
              {
                id: `${canvas}/painting/image`,
                type: "Annotation",
                motivation: "painting",
                target: canvas,
                body: {
                  id: `${service}/full/max/0/default.jpg`,
                  type: "Image",
                  format: "image/jpeg",
                  width,
                  height,
                  // Meadow's IIIF server speaks Image API 3 (sizes such as ^!2048,2048).
                  service: [
                    { id: service, type: "ImageService3", profile: "level2" },
                  ],
                },
              },
            ],
          },
        ],
        annotations: pages,
      },
    ],
  };
}
