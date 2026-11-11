// What the bench remembers in the browser between visits: the variants (there is no
// server store for them) and what was ticked last time.

import { PRESETS } from "./presets";
import type { PickedImage, Variant } from "./types";

export const SETTINGS_KEY = "meadow-transcription-bench";

export interface Settings {
  variants: Variant[];
  images: PickedImage[];
  models: string[];
  /** Ids of the ticked variants. */
  selected: string[];
  customModels: string[];
  columns: number;
}

export const DEFAULT_SETTINGS: Settings = {
  variants: PRESETS,
  images: [],
  models: ["us.anthropic.claude-sonnet-4-6"],
  selected: ["meadow-text-only"],
  customModels: [],
  columns: 1,
};
