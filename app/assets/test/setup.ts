import { afterEach, expect, mock } from "bun:test";
import * as matchers from "@testing-library/jest-dom/matchers";
import { Window } from "happy-dom";
import React from "react";
import {
  elasticSearchCountResponse,
  elasticSearchResponse,
} from "../js/mock-data/elasticsearch-response";

expect.extend(matchers);

const window = new Window({
  url: "http://localhost/",
});
const document = window.document;
document.body.innerHTML = "";

const requestAnimationFrame =
  window.requestAnimationFrame?.bind(window) ??
  ((callback: FrameRequestCallback) =>
    setTimeout(() => callback(performance.now()), 0));
const cancelAnimationFrame =
  window.cancelAnimationFrame?.bind(window) ??
  ((handle: number) => clearTimeout(handle));
Object.assign(window, {
  Error,
  TypeError,
  SyntaxError,
  requestAnimationFrame,
  cancelAnimationFrame,
});

class FileList extends Array<File> {
  item(index: number) {
    return this[index] ?? null;
  }
}

class Image {
  onload: (() => void) | null = null;
  onerror: (() => void) | null = null;
  complete = true;
  naturalHeight = 1;
  naturalWidth = 1;
  height = 1;
  width = 1;
  _src = "";

  set src(value: string) {
    this._src = value;
    queueMicrotask(() => this.onload?.());
  }

  get src() {
    return this._src;
  }
}

const globals = {
  window,
  document,
  navigator: window.navigator,
  location: window.location,
  localStorage: window.localStorage,
  sessionStorage: window.sessionStorage,
  HTMLElement: window.HTMLElement,
  HTMLInputElement: window.HTMLInputElement,
  HTMLTextAreaElement: window.HTMLTextAreaElement,
  HTMLCanvasElement: window.HTMLCanvasElement,
  SVGElement: window.SVGElement,
  Element: window.Element,
  Node: window.Node,
  NodeFilter: window.NodeFilter,
  DocumentFragment: window.DocumentFragment,
  File: window.File,
  FileList: window.FileList ?? FileList,
  FileReader: window.FileReader,
  Blob: window.Blob,
  Event: window.Event,
  CustomEvent: window.CustomEvent,
  MouseEvent: window.MouseEvent,
  KeyboardEvent: window.KeyboardEvent,
  Image: window.Image ?? Image,
  MutationObserver: window.MutationObserver,
  requestAnimationFrame,
  cancelAnimationFrame,
  getComputedStyle: window.getComputedStyle.bind(window),
};

for (const [key, value] of Object.entries(globals)) {
  Object.defineProperty(globalThis, key, {
    configurable: true,
    writable: true,
    value,
  });
}

Object.assign(globalThis, {
  __HONEYBADGER_ENVIRONMENT__: "staging",
  __HONEYBADGER_REVISION__: "1234567",
  __MEADOW_VERSION__: "v1.2.3",
  __ELASTICSEARCH_WORK_INDEX__: "dc-v2-work",
  __ELASTICSEARCH_COLLECTION_INDEX__: "dc-v2-collection",
  __ELASTICSEARCH_FILE_SET_INDEX__: "dc-v2-file-set",
  dataLayer: [],
});
window.dataLayer = globalThis.dataLayer;

const jestGlobal = globalThis.jest ?? {};
Object.defineProperty(globalThis, "jest", {
  configurable: true,
  writable: true,
  value: {
    ...jestGlobal,
    mock: (specifier: string, factory?: () => Record<string, unknown>) => {
      if (typeof factory === "function") {
        mock.module(specifier, factory);
      }
    },
    requireActual: (specifier: string) => require(specifier),
  },
});

class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
}

class IntersectionObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
  takeRecords() {
    return [];
  }
}

Object.defineProperty(globalThis, "ResizeObserver", {
  configurable: true,
  writable: true,
  value: ResizeObserver,
});
Object.defineProperty(globalThis, "IntersectionObserver", {
  configurable: true,
  writable: true,
  value: IntersectionObserver,
});

Object.defineProperty(window.HTMLCanvasElement.prototype, "getContext", {
  configurable: true,
  writable: true,
  value: mock(() => ({
    clearRect: mock(),
    drawImage: mock(),
    fillRect: mock(),
    getImageData: mock(() => ({ data: [] })),
    putImageData: mock(),
    createImageData: mock(() => []),
    setTransform: mock(),
    resetTransform: mock(),
    save: mock(),
    restore: mock(),
    beginPath: mock(),
    moveTo: mock(),
    lineTo: mock(),
    closePath: mock(),
    stroke: mock(),
    translate: mock(),
    scale: mock(),
    rotate: mock(),
    arc: mock(),
    fill: mock(),
    measureText: mock(() => ({ width: 0 })),
    transform: mock(),
    rect: mock(),
    clip: mock(),
  })),
});

if (typeof globalThis.fetch !== "function") {
  Object.defineProperty(globalThis, "fetch", {
    configurable: true,
    writable: true,
    value: mock(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: async () => ({}),
        text: async () => "",
      }),
    ),
  });
}

mock.module("@js/services/elasticsearch", () => ({
  ELASTICSEARCH_PROXY_ENDPOINT: "http://localhost/_search",
  ELASTICSEARCH_WORK_INDEX: "dc-v2-work",
  ELASTICSEARCH_COLLECTION_INDEX: "dc-v2-collection",
  ELASTICSEARCH_FILE_SET_INDEX: "dc-v2-file-set",
  ELASTICSEARCH_AGGREGATION_FIELDS: {},
  allWorksQuery: {
    track_total_hits: true,
  },
  elasticsearchDirectSearch: async () => elasticSearchResponse,
  elasticsearchDirectCount: async () => elasticSearchCountResponse,
  parseESAggregationResults: (aggregations: Record<string, { buckets: [] }>) =>
    Object.entries(aggregations).reduce(
      (acc, [key, value]) => ({ ...acc, [key]: [...value.buckets] }),
      {},
    ),
}));

const useIsAuthorizedMock = mock(() => ({
  user: null,
  isAuthorized: () => true,
}));

mock.module("@js/hooks/useIsAuthorized", () => ({
  default: useIsAuthorizedMock,
}));

mock.module("@js/services/get-api-response-headers", () => ({
  getApiResponseHeaders: async () => ({
    "content-length": "3748",
    "content-type": "application/json; charset=UTF-8",
    date: "Tue, 29 Aug 2033 19:37:08 GMT",
    etag: "aeff5e8cec79a6c5041211d1bab7a137",
  }),
}));

mock.module("@samvera/clover-iiif/viewer", () => ({
  __esModule: true,
  default: (props: { canvasCallback?: (canvasId: string) => void }) => {
    props.canvasCallback?.(
      "https://mat.dev.rdc.library.northwestern.edu:3002/works/a1239c42-6e26-4a95-8cde-0fa4dbf0af6a?as=iiif/canvas/access/0",
    );
    return React.createElement("div");
  },
}));

mock.module("@samvera/clover-iiif/image", () => ({
  __esModule: true,
  default: (props: { src?: string }) =>
    React.createElement("img", {
      alt: "",
      "data-testid": "clover-image",
      src: props.src,
    }),
}));

const reactiveSearchComponent = (testId: string, children?: React.ReactNode) =>
  React.createElement("div", { "data-testid": testId }, children);

mock.module("@appbaseio/reactivesearch", () => ({
  DataSearch: () => reactiveSearchComponent("reactive-search-data-search"),
  MultiList: (props: { componentId?: string }) =>
    reactiveSearchComponent(`reactive-search-multi-list-${props.componentId}`),
  RangeSlider: (props: { componentId?: string }) =>
    reactiveSearchComponent(
      `reactive-search-range-slider-${props.componentId}`,
    ),
  ReactiveBase: (props: { children?: React.ReactNode }) =>
    reactiveSearchComponent("reactive-search-base", props.children),
  ReactiveList: (props: {
    onData?: (data: { resultStats: Record<string, unknown> }) => void;
    onQueryChange?: (
      previousQuery: Record<string, unknown>,
      nextQuery: Record<string, unknown>,
    ) => void;
  }) => {
    props.onData?.({ resultStats: {} });
    props.onQueryChange?.({}, {});
    return reactiveSearchComponent("reactive-search-list");
  },
  SelectedFilters: () => reactiveSearchComponent("reactive-search-filters"),
}));

mock.module("@nulib/use-markdown", () => ({
  default: (content: React.ReactNode) => ({
    jsx: React.createElement(React.Fragment, null, content),
  }),
}));

const { cleanup } = await import("@testing-library/react");

afterEach(() => {
  cleanup();
});
