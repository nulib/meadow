// The variants the bench starts with. "Meadow: text only" is the transcriber as it runs
// today (app/lib/meadow/data/transcriber.ex), "Meadow: passages + boxes" is the same
// transcriber with regions; the others ask for finer regions with the same exclusions.
// Variants are edited and kept in the browser; a run stores a copy of the ones it used.

import type { Variant } from "./types";

const EXCLUDE = `WHAT TO EXCLUDE (do this first, before anything else):
- Mirrored, reversed, or horizontally-flipped text that is visible because it
  has bled through or shown through from the reverse side of the paper. This
  text typically appears fainter or lighter than the primary writing, reads
  right-to-left, and may sit between or behind the primary lines. Treat it as
  part of the paper texture. Do NOT transcribe it. Do NOT note its presence.
  Do NOT add bracketed placeholders like [reversed text] or [illegible].
- Color calibration targets, color bars, rulers, and scanning artifacts.
  These are never part of the resource.
- Cataloger annotations: handwritten identifiers, almost always in pencil,
  made up of uppercase letters, digits, and underscores in a structured
  pattern such as \`BFMF_B25_F04_034\` or \`MS_017_B02\`. These are archival
  control numbers added by staff after the fact and are NOT part of the
  resource. Do not transcribe them and do not note their presence.`;

const TOOL_EXCLUDE =
  "Transcribe only the intentional recto (front-side) text from a document image. " +
  "EXCLUDE any mirrored, reversed, or bleed-through text visible from the verso (back side) — " +
  "such text appears fainter, reads right-to-left, and sits between or behind primary lines; treat it as paper texture. " +
  "EXCLUDE color calibration targets, color bars, rulers, and scanning artifacts. " +
  "EXCLUDE cataloger annotations — handwritten identifiers (typically in pencil) " +
  "consisting of uppercase letters, digits, and underscores in a structured pattern " +
  '(e.g., "BFMF_B25_F04_034"). These are archival control numbers added after the fact, ' +
  "not part of the original document. ";

const NEVER =
  "Do NOT include reversed or mirrored bleed-through text from the verso, " +
  "color bars, rulers, or any scanning artifact. " +
  "Do NOT add bracketed placeholders like [reversed text] or [illegible] " +
  "for excluded bleed-through content. Never abbreviate or truncate.";

const LANGUAGES = {
  type: "array",
  items: { type: "string" },
  description:
    'ISO 639 language codes for languages detected in the transcribed recto text (e.g., ["en", "fr"])',
};

const box = (what: string) => ({
  type: "array",
  items: { type: "integer" },
  minItems: 4,
  maxItems: 4,
  description:
    `Tight bounding box of this ${what} as [x_min, y_min, x_max, y_max], ` +
    "in pixels of the image, origin at its top-left corner.",
});

const schema = (value: unknown) => JSON.stringify(value, null, 2);

const base: Omit<
  Variant,
  "id" | "name" | "notes" | "prompt" | "toolDescription" | "toolSchema"
> = {
  system: "",
  outputMode: "tool",
  toolName: "provide_exact_transcription",
  // Current Claude models reject a forced tool choice and a non-default temperature on
  // Bedrock, so the prompt asks for the tool call instead.
  toolChoice: "auto",
  boxOrder: "xyxy",
  boxUnits: "px",
  maxEdge: 2048,
  // What the transcriber sends. The variants that ask for boxes resize to the model.
  imageFit: "production",
  imageTier: "auto",
  maxTokens: 64000,
  temperature: null,
  additionalFields: "",
};

const prompt = (regions: string, blank: string) =>
  `Transcribe this image by calling the {{tool_name}} tool exactly once. Answer
only with that tool call.

${EXCLUDE}

WHAT TO TRANSCRIBE:
Provide a FULL and EXACT transcription of the text intentionally written or
printed on the front (recto) of the image — every column, heading, caption,
and legible mark, exactly as it appears. ${regions}. The image is {{width}} pixels wide and {{height}} pixels high.
Also detect the language(s) used.

Never abbreviate, summarize, or truncate. You have a 64K output token limit,
so there is NO EXCUSE for omitting any recto text. Blank pages, including
blank versos, have no ${blank}: report an empty ${blank} array.`;

export const PRESETS: Variant[] = [
  {
    ...base,
    id: "meadow-passages",
    name: "Meadow: passages + boxes",
    notes:
      "Meadow's transcriber on the transcriber branch. One region per heading or paragraph, per line where line breaks matter.",
    prompt: prompt(
      `Report the text as a sequence of
passages in the original order (top-to-bottom, left-to-right, one column at
a time), each with a tight bounding box around it. A passage is one heading,
caption, label, or paragraph of running text; where line breaks matter
(letters, handwriting, lists, addresses, tables, poetry) each line is its
own passage. Never put text from two columns or two articles in one
passage`,
      "lines",
    ),
    toolDescription:
      TOOL_EXCLUDE +
      "Blank pages (including blank versos) should be reported with an empty lines array.",
    toolSchema: schema({
      type: "object",
      properties: {
        lines: {
          type: "array",
          description:
            "Every passage of text on the front (recto) of the document, " +
            "in reading order (top-to-bottom, left-to-right, one column at a time). " +
            "A passage is one heading, caption, label, or paragraph of running text; " +
            "where line breaks matter (letters, handwriting, lists, addresses, tables, poetry) " +
            "each line is its own passage. " +
            "Never put text from two columns or two articles in one passage. " +
            NEVER +
            " An empty array for a blank page.",
          items: {
            type: "object",
            properties: {
              text: {
                type: "string",
                description: "The exact text of this passage.",
              },
              box: box("passage"),
            },
            required: ["text", "box"],
          },
        },
        detected_languages: LANGUAGES,
      },
      required: ["lines", "detected_languages"],
    }),
  },
  {
    ...base,
    id: "meadow-text-only",
    name: "Meadow: production (text only)",
    notes:
      "Exactly what Meadow's transcriber sends today: the same prompt and tool, the tool call forced, temperature 0. Run it on Sonnet 4.6 for what production returns. Later models reject a temperature and a forced tool: clear the temperature and set the tool choice to auto to try them.",
    // As in Meadow.Data.Transcriber.build_request_body/4.
    toolChoice: "tool",
    temperature: 0,
    prompt: `Use the {{tool_name}} tool to transcribe this image.

${EXCLUDE}

WHAT TO TRANSCRIBE:
Provide a FULL and EXACT transcription of the text intentionally written or
printed on the front (recto) of the image — every column, heading, caption,
and legible mark, exactly as it appears. Preserve line breaks when they
clarify structure and keep the original order (top-to-bottom, left-to-right).
Also detect the language(s) used.

Never abbreviate, summarize, or truncate. You have a 64K output token limit,
so there is NO EXCUSE for omitting any recto text. Blank pages — including
blank versos — should be transcribed simply as [blank page].`,
    toolDescription:
      TOOL_EXCLUDE +
      'Blank pages (including blank versos) should be reported with transcribed_text set to "[blank page]".',
    toolSchema: schema({
      type: "object",
      properties: {
        transcribed_text: {
          type: "string",
          description:
            "The full and exact text from the front (recto) of the document, " +
            "preserving original line breaks and top-to-bottom, left-to-right order. " +
            NEVER,
        },
        detected_languages: LANGUAGES,
      },
      required: ["transcribed_text", "detected_languages"],
    }),
  },
  {
    ...base,
    imageFit: "model",
    id: "lines",
    name: "Lines + boxes",
    notes:
      "One region per printed or written line. On a dense page (the newspaper) Sonnet 5.5 stopped early when asked for this.",
    prompt: prompt(
      `Report the text line by line, as it
is printed or written, in the original order (top-to-bottom, left-to-right,
one column at a time), each line with a tight bounding box around it. A line
never spans two columns`,
      "lines",
    ),
    toolDescription:
      TOOL_EXCLUDE +
      "Blank pages (including blank versos) should be reported with an empty lines array.",
    toolSchema: schema({
      type: "object",
      properties: {
        lines: {
          type: "array",
          description:
            "Every line of text on the front (recto) of the document, as printed or written, " +
            "in reading order (top-to-bottom, left-to-right, one column at a time). " +
            NEVER +
            " An empty array for a blank page.",
          items: {
            type: "object",
            properties: {
              text: {
                type: "string",
                description: "The exact text of this line.",
              },
              box: box("line"),
            },
            required: ["text", "box"],
          },
        },
        detected_languages: LANGUAGES,
      },
      required: ["lines", "detected_languages"],
    }),
  },
  {
    ...base,
    imageFit: "model",
    id: "words",
    name: "Lines > words + boxes",
    notes:
      "The ideal output: every line with its box, and every word in it with its own box.",
    prompt: prompt(
      `Report the text line by line, as it
is printed or written, in the original order (top-to-bottom, left-to-right,
one column at a time). Give each line a tight bounding box, and list its
words in order, each with its own tight bounding box. A word is what stands
between two spaces, with its punctuation. A line never spans two columns`,
      "lines",
    ),
    toolDescription:
      TOOL_EXCLUDE +
      "Blank pages (including blank versos) should be reported with an empty lines array.",
    toolSchema: schema({
      type: "object",
      properties: {
        lines: {
          type: "array",
          description:
            "Every line of text on the front (recto) of the document, as printed or written, " +
            "in reading order (top-to-bottom, left-to-right, one column at a time). " +
            NEVER +
            " An empty array for a blank page.",
          items: {
            type: "object",
            properties: {
              text: {
                type: "string",
                description: "The exact text of this line.",
              },
              box: box("line"),
              words: {
                type: "array",
                description: "Every word of this line, in order.",
                items: {
                  type: "object",
                  properties: {
                    text: {
                      type: "string",
                      description: "The word, with its punctuation.",
                    },
                    box: box("word"),
                  },
                  required: ["text", "box"],
                },
              },
            },
            required: ["text", "box", "words"],
          },
        },
        detected_languages: LANGUAGES,
      },
      required: ["lines", "detected_languages"],
    }),
  },
];
