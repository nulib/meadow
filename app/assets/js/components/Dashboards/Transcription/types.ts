// Types for the transcription bench: what the browser keeps (variants, the setup) and
// what the API returns (runs and their results).

export type OutputMode = "tool" | "text";
export type ToolChoice = "auto" | "any" | "tool";
/** The order of the four numbers a model gives for a box. */
export type BoxOrder = "xyxy" | "xywh" | "yxyx";
/** What the numbers count: pixels of the image sent, a 0..1000 grid, or 0..1 fractions. */
export type BoxUnits = "px" | "1000" | "frac";
export type ImageFit = "production" | "model";
/** Standard: 1568 px and 1568 visual tokens. High: 2576 px and 4784 (Claude 4.7 on). */
export type ImageTier = "auto" | "standard" | "high";

/**
 * Everything that can change between two transcription attempts on the same image and
 * model: the prompt, the structured output, how boxes are read, and the image sent.
 * `prompt`, `system`, `toolDescription` and `toolSchema` may use {{width}}, {{height}}
 * (the size of the image sent) and {{tool_name}}.
 */
export interface Variant {
  id: string;
  name: string;
  notes: string;
  system: string;
  prompt: string;
  outputMode: OutputMode;
  toolName: string;
  toolDescription: string;
  /** JSON Schema of the tool's input, as text so it can be edited freely. */
  toolSchema: string;
  toolChoice: ToolChoice;
  boxOrder: BoxOrder;
  boxUnits: BoxUnits;
  /** Longest edge of the image asked of the IIIF server (the transcriber asks for 2048). */
  maxEdge: number;
  /**
   * "production" sends that image as it is, and a model whose limits it exceeds resizes
   * it out of sight. "model" has the IIIF server resize it to what the model would make
   * of it, as Anthropic recommends when asking for coordinates. Absent means production.
   */
  imageFit?: ImageFit;
  /** The limits the model resizes to: its own ("auto") or a tier named here. */
  imageTier?: ImageTier;
  maxTokens: number;
  /** null leaves temperature out of the request (current models reject it). */
  temperature: number | null;
  /** JSON object merged into Converse's additionalModelRequestFields, or "". */
  additionalFields: string;
}

export interface Region {
  index: number;
  /** The array the region came from in the model's output: "lines", "words", ... */
  level: string;
  text: string;
  /** [x, y, width, height] as fractions (0..1) of the image, or null without a usable box. */
  box: [number, number, number, number] | null;
  /** The box exactly as the model gave it. */
  rawBox: unknown;
  /** Index of the region this one is nested in (a word's line), if any. */
  parent: number | null;
}

export interface Parsed {
  text: string;
  regions: Region[];
  /** Level names in the order they first appear, outermost first. */
  levels: string[];
  languages: string[];
  structured: boolean;
  warnings: string[];
}

export type ResultStatus =
  | "queued"
  | "running"
  | "done"
  | "error"
  | "cancelled";

export interface Usage {
  inputTokens?: number;
  outputTokens?: number;
  totalTokens?: number;
}

export interface Result {
  id: string;
  /** Goes up each time the result is run again. */
  attempt: number;
  fileSetId: string;
  label: string | null;
  /** IIIF Image API base URL of the file set. */
  imageUrl: string | null;
  model: string;
  variantId: string;
  status: ResultStatus;
  error?: string | null;
  startedAt?: string | null;
  durationMs?: number | null;
  /** Size of the full image (the Canvas). */
  imageWidth?: number | null;
  imageHeight?: number | null;
  /** Size of the image sent to the model. */
  sentWidth?: number | null;
  sentHeight?: number | null;
  sentBytes?: number | null;
  /** The size the model resized the image to; its pixel boxes are read against it. */
  processedWidth?: number | null;
  processedHeight?: number | null;
  stopReason?: string | null;
  usage?: Usage | null;
  toolInput?: string | null;
  text?: string | null;
  reasoning?: string | null;
  /** The Converse request, with the image bytes left out. */
  request?: unknown;
  parsed?: Parsed | null;
}

export interface RunImage {
  fileSetId: string;
  label: string | null;
}

export interface RunSummary {
  id: string;
  name: string | null;
  author: string | null;
  insertedAt: string;
  /** The variants as they were when the run started. */
  variants: Variant[];
  images: RunImage[];
  models: string[];
  total: number;
  done: number;
  failed: number;
  cancelled: number;
  active: number;
}

export interface Run extends RunSummary {
  results: Result[];
}

export interface TranscribableFileSet {
  id: string;
  accessionNumber: string | null;
  label: string | null;
  representativeImageUrl: string | null;
  workId: string | null;
  workTitle: string | null;
  workAccessionNumber: string | null;
  collectionId: string | null;
  collectionTitle: string | null;
}

export interface ModelInfo {
  id: string;
  label: string;
}

/** A picked image, kept with enough to show it without asking the server again. */
export interface PickedImage {
  id: string;
  label: string;
  thumbnail: string | null;
}
