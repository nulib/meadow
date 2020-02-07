import { library } from "@fortawesome/fontawesome-svg-core";
import { fab } from "@fortawesome/free-brands-svg-icons";
import {
  faAngleDown,
  faEdit,
  faFileDownload,
  faFileUpload,
  faPlus,
  faProjectDiagram,
  faThumbsUp,
  faTrash,
  faUser
} from "@fortawesome/free-solid-svg-icons";

export default function setupFontAwesome() {
  return library.add(
    fab,
    faAngleDown,
    faEdit,
    faFileDownload,
    faFileUpload,
    faPlus,
    faProjectDiagram,
    faThumbsUp,
    faTrash,
    faUser
  );
}
