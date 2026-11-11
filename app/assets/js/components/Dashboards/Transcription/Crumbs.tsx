import type { ComponentType } from "react";
import { Breadcrumbs } from "@js/components/UI/UI";

export interface Crumb {
  label: string;
  route?: string;
  isActive: boolean;
}

/** Meadow's Breadcrumbs (a .jsx component), with the props TypeScript cannot infer. */
const Crumbs = Breadcrumbs as unknown as ComponentType<{ items: Crumb[] }>;

export default Crumbs;
