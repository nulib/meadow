/**
 * The most transcriptions one run may hold, whatever the images, models and variants
 * picked. The server enforces the same number (Meadow.TranscriptionBench); this one only
 * decides what the form says and when its button is disabled.
 */
export const MAX_TRANSCRIPTIONS = 10;

export interface RunSize {
  images: number;
  models: number;
  variants: number;
  total: number;
  /** Something of each kind is picked. */
  runnable: boolean;
  overCap: boolean;
}

export function runSize(
  images: number,
  models: number,
  variants: number,
): RunSize {
  const total = images * models * variants;
  return {
    images,
    models,
    variants,
    total,
    runnable: total > 0,
    overCap: total > MAX_TRANSCRIPTIONS,
  };
}

const count = (n: number, noun: string) => `${n} ${noun}${n === 1 ? "" : "s"}`;

/** "2 images x 3 models x 2 variants = 12 transcriptions" */
export function arithmetic(size: RunSize): string {
  return `${count(size.images, "image")} × ${count(size.models, "model")} × ${count(
    size.variants,
    "variant",
  )} = ${count(size.total, "transcription")}`;
}
