import "@testing-library/jest-dom/extend-expect";
import setupFontAwesome from "./js/font-awesome-setup";

setupFontAwesome();
jest.setTimeout(10000);
jest.mock("@js/services/elasticsearch");
