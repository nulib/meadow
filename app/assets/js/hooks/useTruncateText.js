export default function useTruncateText() {
  function truncate(text = "", number) {
    if (text.length <= number) {
      return text;
    }
    return text.slice(0, number) + "...";
  }
  return { truncate };
}
