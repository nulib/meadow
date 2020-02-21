import { library } from "@fortawesome/fontawesome-svg-core";
import { fab } from "@fortawesome/free-brands-svg-icons";
import {
  faAngleDown,
  faBell,
  faCheck,
  faEdit,
  faFileDownload,
  faFileUpload,
  faHome,
  faLeaf,
  faPlus,
  faProjectDiagram,
  faSearch,
  faThumbsUp,
  faTrash,
  faUser
} from "@fortawesome/free-solid-svg-icons";

export default function setupFontAwesome() {
  return library.add(
    fab,
    faAngleDown,
    faBell,
    faCheck,
    faEdit,
    faFileDownload,
    faFileUpload,
    faHome,
    faLeaf,
    faPlus,
    faProjectDiagram,
    faSearch,
    faThumbsUp,
    faTrash,
    faUser
  );
}
