export async function getManifest(url) {
  return new Promise((resolve, reject) => {
    process.nextTick(() =>
      resolve({
        description: ["asdfasdf"],
        label:
          "Adam Night scene in Washington, D.C. during the Vietnam Moratorium",
        sequences: [
          {
            canvases: [
              {
                height: "480",
                images: [
                  {
                    motivation: "sc:painting",
                    resource: {
                      description: "yo yo",
                      label: "inu-dil-c343d206-209b-48ce-b336-8f6ab12ded02.tif",
                      service: {
                        profile: "http://iiif.io/api/image/2/level2.json",
                        "@context": "http://iiif.io/api/image/2/context.json",
                        "@id":
                          "https://devbox.library.northwestern.edu:8183/iiif/2/2206b61b-5d4a-41b5-bb93-0e78a9e480f9",
                      },
                      "@id":
                        "https://devbox.library.northwestern.edu:8183/iiif/2/2206b61b-5d4a-41b5-bb93-0e78a9e480f9/full/600,/0/default.jpg",
                      "@type": "dctypes:Image",
                    },
                    "@type": "oa:Annotation",
                  },
                ],
                label: "inu-dil-c343d206-209b-48ce-b336-8f6ab12ded02.tif",
                width: "640",
                "@id":
                  "https://devbox.library.northwestern.edu:9001/dev-pyramids/public/0c/f6/1b/38/-5/50/f-/4f/cf/-a/ed/b-/38/07/5a/7c/7a/e0-manifest.json/canvas/2206b61b-5d4a-41b5-bb93-0e78a9e480f9",
                "@type": "sc:Canvas",
              },
            ],
            "@context": "http://iiif.io/api/presentation/2/context.json",
            "@id": "/sequence/normal",
            "@type": "sc:Sequence",
          },
        ],
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id":
          "https://devbox.library.northwestern.edu:9001/dev-pyramids/public/0c/f6/1b/38/-5/50/f-/4f/cf/-a/ed/b-/38/07/5a/7c/7a/e0-manifest.json",
        "@type": "sc:Manifest",
      })
    );
  });
}
