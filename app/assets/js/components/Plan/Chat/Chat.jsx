import React from "react";
import PlanChatForm from "@js/components/Plan/Chat/Form";
import PlanChatTranscript from "@js/components/Plan/Chat/Transcript";

const mockMessages = [
  {
    content:
      "You are viewing the Image work Kalispel Village, collection Edward S. Curtis's The North American Indian. accession number P0333_9972447644202441_39.",
    isUser: false,
    type: "message",
  },
  // add long verbose request from human user about updating subjects and description
  {
    content:
      "I would like to update the description and subjects for this work. Can you help me with that?",
    isUser: true,
    type: "message",
  },
  {
    content:
      "Certainly! We offer a variety of services including high-resolution scanning, color correction, and digital restoration. Our team of experts can help enhance the quality of your images while preserving their original integrity. Additionally, we provide metadata tagging and cataloging services to help organize and manage your digital assets effectively. If you have any specific requirements or questions, feel free to let us know!",
    isUser: false,
    type: "message",
  },
  // give a full paragraph response
  {
    content:
      "Actually, I was hoping you could draft a plan for updating the description and subjects based on the content of the image. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec at augue imperdiet, vulputate magna ac, ultricies mi. Nullam ut ullamcorper sapien, id consectetur dolor. Donec vitae gravida sem, eu aliquam nibh. Aenean lobortis diam libero, pellentesque vehicula nibh rhoncus consectetur. Sed id bibendum libero, in tincidunt metus. Suspendisse efficitur nec mi id iaculis. Duis tellus arcu, eleifend quis urna et, commodo varius risus. Sed dictum orci in lorem tincidunt, sed ultricies risus laoreet. Could you help with that?",
    isUser: true,
    type: "message",
  },
  // provide a detail response with a link to a plan
  {
    content:
      "Sure! We can do that... We will handle this by drafting a plan that updates the description and subjects based on the content of the image. You can view the plan here: [link to plan]",
    isUser: false,
    type: "message",
  },
];

const PlanChat = () => {
  return (
    <div className="chat">
      <PlanChatTranscript messages={mockMessages} />
      <PlanChatForm />
    </div>
  );
};

export default PlanChat;
