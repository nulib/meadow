import { useSubscription } from "@apollo/client";
import { FILE_SET_ANNOTATION } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";

export function useFileSetAnnotation(fileSetId) {
  try {
    const { data, loading, error } = useSubscription(FILE_SET_ANNOTATION, {
      variables: { fileSetId },
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    return { data, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
