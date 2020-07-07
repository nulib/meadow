import React from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import BatchEditPreviewItems from "../../components/BatchEdit/PreviewItems";
import BatchEditTabs from "../../components/BatchEdit/Tabs";
const selectedItemsMock = [
  {
    accessionNumber: "Xample-b-25",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 1",
    },
    id: "0239eeb9-1763-4c78-8948-853365e487dc",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/ed15d61e-1e47-4b5e-8447-bb39fb007a46",
  },
  {
    accessionNumber: "Xample-b-39",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 2",
    },
    id: "0335b57f-33ad-4c85-bfd9-5260b2c183d6",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/ecb6ecbb-1c1a-4ee1-8697-6029b361d4ba",
  },
  {
    accessionNumber: "Xample-b-31",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 3",
    },
    id: "03a28ff0-ced5-4a9f-ad86-b4316150626a",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/aa6433a7-aceb-431c-8446-0dab874ae3ed",
  },
  {
    accessionNumber: "Xample-b-1",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 4",
    },
    id: "0eabf045-6ab3-4e56-bce4-85b2d31c288f",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/0632ed81-eb54-4885-99bf-05ef77807491",
  },
  {
    accessionNumber: "Xample-b-26",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 5",
    },
    id: "1572ca68-68a7-45e0-8feb-7e480e9a6c00",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/445ac3c0-da0d-4ea4-ab75-e20041870e54",
  },
  {
    accessionNumber: "Xample-b-12",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 6",
    },
    id: "175d9637-2122-4dda-bcd8-3e27c541f29f",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/ca8bad27-ef98-40b5-a08e-1c9d718b8c65",
  },
  {
    accessionNumber: "Xample-b-46",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 7",
    },
    id: "182cb6b8-da7c-4a36-8eb8-39a225c5eb60",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/3ea8cfb0-670f-4937-a152-dd0ed085040d",
  },
  {
    accessionNumber: "Xample-b-4",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 8",
    },
    id: "221d72cd-d270-496e-96e2-2468427e7282",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/482939cd-7325-4d08-87e2-4d621391973d",
  },
  {
    accessionNumber: "Xample-b-38",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 9",
    },
    id: "23c1937e-cf15-40ea-bdd8-214b317c2b3c",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/68fcd9c1-5c19-4d19-9c46-96bfb8f7b346",
  },
  {
    accessionNumber: "Xample-b-29",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 10",
    },
    id: "2f6212c3-a54b-467d-a24f-bcff05e45164",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/f2dd0e33-1953-49c7-8f42-756659ddb3a0",
  },
  {
    accessionNumber: "Xample-b-42",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 11",
    },
    id: "345a4bc6-4d1c-4d9e-a3eb-0f6017a48ad5",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/cd027c51-7b94-4ee6-98e8-2d7a70de3505",
  },
  {
    accessionNumber: "Xample-b-7",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 12",
    },
    id: "35f495e9-8568-448f-8e9f-30b327997354",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/e4104eff-4750-4502-9ff7-41db2e1e6bba",
  },
  {
    accessionNumber: "Xample-b-50",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "This is the tiele",
    },
    id: "3623e511-ccce-4a97-875b-ada07d6bda8d",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/7835f91e-ead1-4d24-a309-457575935dd4",
  },
  {
    accessionNumber: "Xample-b-40",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 13",
    },
    id: "39197371-f6fb-4cf5-9c91-3e5db18948e0",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/e679591c-a888-4eb0-aa93-0c111a746169",
  },
  {
    accessionNumber: "Xample-b-11",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 14",
    },
    id: "3a37aacb-6f5f-4c9d-89f4-cb0ea4025224",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/580f0873-8240-4fd1-8548-1edc049927f3",
  },
  {
    accessionNumber: "Xample-b-20",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "3a48b238-526b-4b48-a3eb-ce9ca3521274",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/3de06650-b325-437e-895a-684cf9ea7329",
  },
  {
    accessionNumber: "Xample-b-45",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "3e7b1526-45ad-484e-9a90-4b72c92aac43",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/79f5b9d9-eb05-4b0d-85da-e25107abbde2",
  },
  {
    accessionNumber: "Xample-b-30",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "3ff92cd2-d9dc-44ec-9ba2-919b530fee46",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/9617de60-70a7-4bad-9202-52618c90ebdc",
  },
  {
    accessionNumber: "Xample-b-9",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "5e82f3cd-09ce-484e-9443-eaf5432e05ef",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/8aa71c59-9a2b-4f5e-8435-e353deac4beb",
  },
  {
    accessionNumber: "Xample-b-49",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "66a1c086-2439-4cae-aab9-6e137d0e3979",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/76477e16-5cfd-476f-8547-d0e63a2c5717",
  },
  {
    accessionNumber: "Xample-b-43",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "66df6d94-cbc8-4180-bdb8-bfff698748c9",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/5f9af275-fc60-4295-bc2b-b3813d32df38",
  },
  {
    accessionNumber: "Xample-b-33",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "68dacfcc-2abb-4786-8ba6-ccd67ea13bc7",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/63daf094-3732-4984-8824-98fff6089a63",
  },
  {
    accessionNumber: "Xample-b-36",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "6a0def65-d97a-4ed1-b3c4-9a420038ddc5",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/10b0f6a5-ce98-49e0-977d-4aea536b1963",
  },
  {
    accessionNumber: "Xample-b-35",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "6b472bd5-f792-4504-92b9-e082d7fc7db4",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/64239b16-84f3-4c5b-9387-5e060c06c468",
  },
  {
    accessionNumber: "Xample-b-37",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "6fc37ff0-b1f3-48c6-b7d0-6158c45da648",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/32ea44a9-f38c-42ef-9f64-1d05fd4098e7",
  },
  {
    accessionNumber: "Xample-b-21",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "7b0d4ea3-3881-4a03-9034-9547e6e3d71b",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/fcc2b2f3-1950-4f13-9830-1f1d98557c93",
  },
  {
    accessionNumber: "Xample-b-34",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "7cef3024-f175-4ea8-9e1e-a2549775a025",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/b0fb7ac4-89e6-48d2-ba95-0270917fd0e0",
  },
  {
    accessionNumber: "Xample-b-19",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "81554fbf-fd2c-4564-b355-e31951fcbdbb",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/ec121d83-3da8-4644-a548-a6e9614d51c4",
  },
  {
    accessionNumber: "Xample-b-44",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "83692178-42fe-4cb4-a509-0c2aef2c42a3",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/66e2304a-cda2-4d89-8c0f-ad60ba7fa27e",
  },
  {
    accessionNumber: "Xample-b-18",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "9450531f-5793-4fe8-9cb0-73d28ede0ab6",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/d7fa6cae-62a2-41a2-be5e-558ad190348c",
  },
  {
    accessionNumber: "Xample-b-28",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "99daa290-ca28-480c-b6f6-701813d0a39c",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/176059ad-f399-42d0-9ad2-02e9dc4a631b",
  },
  {
    accessionNumber: "Xample-b-41",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "9b55937b-93a2-46ed-9c63-1706c9ac6de4",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/6187637f-05cf-4601-9cd0-735def29615c",
  },
  {
    accessionNumber: "Xample-b-17",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "9bec262d-237f-4675-9d5a-28549bed1e78",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/c550d2ba-6668-47b5-9045-49691feb5544",
  },
  {
    accessionNumber: "Xample-b-6",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "9faadeec-f6e0-4549-af66-7725226e6fc2",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/a1a61f72-7334-481e-b926-721fc970f68d",
  },
  {
    accessionNumber: "Xample-b-48",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "a17cfbef-99bd-4e8c-833b-066ae732b8df",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/bca693ef-f1de-4b50-b89b-3c4a507c4bc5",
  },
  {
    accessionNumber: "Xample-b-13",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "aa6ba0a5-4ef2-4dac-b5d8-7828e4d2d059",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/9b389764-9ee1-4c4c-9721-71471993a6d5",
  },
  {
    accessionNumber: "Xample-b-23",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "bc259aa1-7313-487a-bcac-2b7426033dbe",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/3bc300b7-95a6-45c1-9e46-f740b41ff5c1",
  },
  {
    accessionNumber: "Xample-b-14",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "bf8b3627-5205-4c50-a0ea-e2e85f80888d",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/ffe039bd-5534-42bc-94aa-0b795e306e88",
  },
  {
    accessionNumber: "Xample-b-10",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "c8ea8e66-e82b-4485-b85c-1488cb4299f0",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/230ce46e-b7ce-442c-9051-bca49bf291da",
  },
  {
    accessionNumber: "Xample-b-47",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "d2ab5599-b6e4-4680-b896-ebf15cf3bc35",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/bf2e6dc9-3e1b-410c-9015-ddaf2ea71eea",
  },
  {
    accessionNumber: "Xample-b-5",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "This is the title",
    },
    id: "d7b4f2f6-16e1-4ede-976a-c2bde0d1411a",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/cb81668d-5384-4e91-abd1-08e38bd4db24",
  },
  {
    accessionNumber: "Xample-b-24",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "dea5af9f-bd52-491b-9224-f93e9fee24cd",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/f771fec4-ebc1-41ce-8678-c04e728ae047",
  },
  {
    accessionNumber: "Xample-b-8",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "e36828d0-0f56-4ef8-8ed1-e372218ae80b",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/0eaa633c-5ab0-4ca2-8605-9b870d3674b9",
  },
  {
    accessionNumber: "Xample-b-15",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "e9bb0438-8795-4a53-a29e-d9c9f47e8914",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/6f901eac-abc0-47de-a5cb-3f98d0e3d3b2",
  },
  {
    accessionNumber: "Xample-b-32",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "ec1e79de-d029-4f8c-8627-712a4a1e2375",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/3379ae60-28f7-45cb-9341-bcd1dfe75b7c",
  },
  {
    accessionNumber: "Xample-b-2",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "f1c804e1-cc31-44be-a883-3d59c74ea5c9",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/574617f1-0bf4-40dd-905d-44887fe25860",
  },
  {
    accessionNumber: "Xample-b-16",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "f64df63c-cac2-4a9a-ab93-9ea0c14766e2",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/c0e6315f-bddb-4271-8ef7-f2a70d752285",
  },
  {
    accessionNumber: "Xample-b-27",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "fc3a940a-89ab-4e76-af7e-d7b77f1b3d33",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/75897553-62a7-4a49-9216-ac6f41626edb",
  },
  {
    accessionNumber: "Xample-b-22",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "fc3e28b2-89c0-4bbb-b6c2-e80048c27e62",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/e5ba9578-b13a-497a-b345-cbc238b2530c",
  },
  {
    accessionNumber: "Xample-b-3",
    collection: null,
    descriptiveMetadata: {
      caption: [],
      identifier: [],
      title: "Sample Title 155",
    },
    id: "ff4a8216-6604-4520-b28d-14b987db22d7",
    representativeImage:
      "https://devbox.library.northwestern.edu:8183/iiif/2/032e40fc-01b0-4def-933d-cbd7e68fa20a",
  },
];
export default function BatchEdit() {
  return (
    <Layout>
      <section className="section">
        <div className="container">
          <UIBreadcrumbs
            items={[
              { label: "Batch Edit", route: "/batch-edit", isActive: true },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="title">
              Batch Edit
            </h1>
            <p data-testid="num-results">Editing 50 rows</p>
          </div>

          <div className="box" data-testid="preview-wrapper">
            <BatchEditPreviewItems selectedItems={selectedItemsMock} />
          </div>

          <div className="box" data-testid="tabs-wrapper">
            <BatchEditTabs />
          </div>
        </div>
      </section>
    </Layout>
  );
}
